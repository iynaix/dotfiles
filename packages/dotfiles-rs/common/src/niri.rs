use itertools::Itertools;
use niri_ipc::{
    Action, Output, Request, Response, SizeChange::SetProportion, Window, Workspace, socket::Socket,
};

use crate::MIN_ULTRAWIDE_RATIO;

pub trait WindowExt {
    fn col(&self) -> Option<usize>;

    fn row(&self) -> Option<usize>;
}

impl WindowExt for Window {
    fn col(&self) -> Option<usize> {
        self.layout.pos_in_scrolling_layout.map(|(col, _)| col)
    }

    fn row(&self) -> Option<usize> {
        self.layout.pos_in_scrolling_layout.map(|(_, row)| row)
    }
}

pub trait MonitorExt {
    fn dimensions(&self) -> Option<(i32, i32)>;

    fn aspect_ratio(&self) -> Option<f64> {
        self.dimensions().map(|(w, h)| f64::from(w) / f64::from(h))
    }

    fn is_vertical(&self) -> bool {
        self.aspect_ratio().is_some_and(|ratio| ratio < 1.0)
    }

    fn is_ultrawide(&self) -> bool {
        self.aspect_ratio()
            .is_some_and(|ratio| ratio >= MIN_ULTRAWIDE_RATIO)
    }

    fn is_fullscreen_window(&self, win: &Window) -> bool {
        self.dimensions().map(|(w, h)| {
            let (win_w, win_h) = win.layout.window_size;
            w == win_w && h == win_h
        }) == Some(true)
    }

    fn window_ratio(&self, win: &Window) -> Option<f64> {
        self.dimensions().map(|(w, _)| {
            let win_w = win.layout.window_size.0;
            f64::from(win_w) / f64::from(w)
        })
    }
}

impl MonitorExt for Output {
    fn dimensions(&self) -> Option<(i32, i32)> {
        self.logical
            .map(|logical| (logical.width as i32, logical.height as i32))
    }
}

fn handle_single_window(socket: &mut Socket, win: &Window, mon: &Output) {
    let Some(width_percent) = mon.window_ratio(win) else {
        return;
    };

    if width_percent < 0.9 {
        // focus the window before resizing (necessary when moving between workspaces)
        socket
            .send(Request::Action(Action::FocusWindow { id: win.id }))
            .expect("failed to send MaximizeWindowById")
            .ok();

        // maximize-column toggles width, which can cause races where it is resized back to 50%
        // so set the width to 50% first
        socket
            .send(Request::Action(Action::SetWindowWidth {
                id: Some(win.id),
                change: SetProportion(50.0),
            }))
            .ok();

        socket
            .send(Request::Action(Action::MaximizeColumn {}))
            .expect("failed to send MaximizeWindowById")
            .ok();
    }
}

fn handle_vertical_monitor(socket: &mut Socket, columns: &[Vec<Window>], max_rows: usize) {
    for (i, col) in columns.iter().enumerate() {
        // do nothing for first column
        if i == 0 {
            continue;
        }

        let mut prev_column_cnt = columns[i - 1].len();
        for win in col {
            // previous column is full
            if prev_column_cnt >= max_rows {
                // maximize subsequent columns
                socket
                    .send(Request::Action(Action::MaximizeColumn {}))
                    .expect("failed to send MaximizeColumn")
                    .expect("invalid reply for MaximizeColumn");
                continue;
            }

            // expel window from column
            socket
                .send(Request::Action(Action::ConsumeOrExpelWindowLeft {
                    id: Some(win.id),
                }))
                .expect("failed to send ExpelWindowFromColumn")
                .expect("invalid reply for ExpelWindowFromColumn");

            prev_column_cnt += 1;
        }
    }
}

fn handle_horizontal_monitor(
    socket: &mut Socket,
    columns: &[Vec<Window>],
    initial_window: Option<&Window>,
    mon: &Output,
) {
    let max_cols = if mon.is_ultrawide() { 3 } else { 2 };

    if columns.len() > max_cols {
        return;
    }

    let target_ratio = 1.0 / columns.len().min(max_cols) as f64;

    for col in columns {
        // it's already the correct size
        let Some(col_ratio) = mon.window_ratio(&col[0]) else {
            return;
        };

        if (target_ratio - col_ratio).abs() < 0.01 {
            continue;
        }

        // set column ratio as percentage
        socket
            .send(Request::Action(Action::SetWindowWidth {
                id: Some(col[0].id),
                change: SetProportion(target_ratio * 100.0),
            }))
            .ok();
    }

    // focus first column to scroll all the way to the left
    socket
        .send(Request::Action(Action::FocusColumnFirst {}))
        .expect("failed to send FocusColumnFirst")
        .ok();

    // small sleep to allow first column to be focused
    std::thread::sleep(std::time::Duration::from_millis(50));

    if let Some(initial_window) = initial_window {
        socket
            .send(Request::Action(Action::FocusWindow {
                id: initial_window.id,
            }))
            .expect("failed to send FocusWindow")
            .ok();
    }
}

pub fn resize_workspace<Windows, Workspaces>(
    workspace_id: u64,
    window: Option<&Window>,
    windows: Windows,
    workspaces: Workspaces,
) where
    Windows: IntoIterator<Item = Window>,
    Workspaces: IntoIterator<Item = Workspace>,
{
    let mut has_floating = false;
    let mut wksp_windows = windows
        .into_iter()
        .filter(|win| win.workspace_id == Some(workspace_id))
        // don't include floating windows
        .filter(|win| {
            if win.is_floating {
                has_floating = true;
            }
            !win.is_floating
        })
        // the windows might not be in the correct order
        .sorted_by_key(|win| win.layout.pos_in_scrolling_layout)
        .filter(|win| win.layout.pos_in_scrolling_layout.is_some())
        .collect_vec();

    // don't do anything if there are floating windows (e.g. save dialogs etc)
    if has_floating {
        return;
    }

    // check if vertical monitor
    let mut socket = Socket::connect().expect("failed to connect to niri socket");
    let Ok(Response::Outputs(monitors)) = socket
        .send(Request::Outputs)
        .expect("failed to send Outputs")
    else {
        panic!("invalid reply for Outputs");
    };

    let Some(wksp) = workspaces.into_iter().find(|wksp| wksp.id == workspace_id) else {
        return;
    };

    let Some(mon) = monitors
        .values()
        .find(|mon| Some(&mon.name) == wksp.output.as_ref())
    else {
        return;
    };

    let mut has_fullscreen_window = false;
    wksp_windows.retain(|win| {
        let is_fullscreen = mon.is_fullscreen_window(win);

        if is_fullscreen {
            has_fullscreen_window = true;
        }
        !is_fullscreen
    });

    // don't mess with fullscreen windows
    if has_fullscreen_window {
        return;
    }

    // single window should be maximized
    if wksp_windows.len() == 1 {
        handle_single_window(&mut socket, &wksp_windows[0], mon);
        return;
    }

    let columns = wksp_windows
        .into_iter()
        .chunk_by(WindowExt::col)
        .into_iter()
        .map(|(_, chunk)| chunk.collect_vec())
        .collect_vec();

    if mon.is_vertical() {
        // NOTE: hardcoded to 3 rows for now
        handle_vertical_monitor(&mut socket, &columns, 3);
    } else {
        handle_horizontal_monitor(&mut socket, &columns, window, mon);
    }
}
