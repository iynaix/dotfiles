use itertools::Itertools;
use niri_ipc::{
    Action, LogicalOutput, Request, Response, SizeChange::SetProportion, Transform, Window,
    Workspace, socket::Socket,
};

fn handle_single_window(socket: &mut Socket, win: &Window, logical: &LogicalOutput) {
    let width_percent = f64::from(win.layout.window_size.0) / f64::from(logical.width);
    if width_percent < 0.9 {
        // focus the window before resizing (necessary when moving between workspaces)
        socket
            .send(Request::Action(Action::FocusWindow { id: win.id }))
            .expect("failed to send MaximizeWindowById")
            .ok();

        // maximize-column toggles width, which can cause races where it is resized back to 50%
        // so set the width to 50% first
        socket
            .send(Request::Action(Action::SetColumnWidth {
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
    mon_width: f64,
    max_cols: usize,
) {
    if columns.len() > max_cols {
        return;
    }

    #[allow(clippy::cast_precision_loss)]
    let target_ratio = 1.0 / columns.len().min(max_cols) as f64;

    for col in columns {
        // it's already the correct size
        let col_ratio = f64::from(col[0].layout.window_size.0) / mon_width;
        if (target_ratio - col_ratio).abs() < 0.01 {
            continue;
        }

        // focus first window in column
        socket
            .send(Request::Action(Action::FocusWindow { id: col[0].id }))
            .expect("failed to send FocusWindow")
            .ok();

        // set column ratio as percentage
        socket
            .send(Request::Action(Action::SetColumnWidth {
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
    let mut wksp_windows = windows
        .into_iter()
        .filter(|win| win.workspace_id == Some(workspace_id))
        // don't include floating windows
        .filter(|win| !win.is_floating)
        // the windows might not be in the correct order
        .sorted_by_key(|win| win.layout.pos_in_scrolling_layout)
        .filter(|win| win.layout.pos_in_scrolling_layout.is_some())
        .collect_vec();

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

    let Some(logical) = monitors.values().find_map(|mon| {
        if Some(&mon.name) != wksp.output.as_ref() {
            return None;
        }

        mon.logical
    }) else {
        return;
    };

    let is_vertical = matches!(
        logical.transform,
        Transform::_90 | Transform::_270 | Transform::Flipped90 | Transform::Flipped270
    );

    let mut has_fullscreen_window = false;
    #[allow(clippy::cast_sign_loss)]
    wksp_windows.retain(|win| {
        let (win_w, win_h) = win.layout.window_size;
        let is_fullscreen = win_w as u32 == logical.width && win_h as u32 == logical.height;

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
        handle_single_window(&mut socket, &wksp_windows[0], &logical);
        return;
    }

    let columns = wksp_windows
        .into_iter()
        .chunk_by(|win| win.layout.pos_in_scrolling_layout.map(|(col, _)| col))
        .into_iter()
        .map(|(_, chunk)| chunk.collect_vec())
        .collect_vec();

    if is_vertical {
        // NOTE: hardcoded to 3 rows for now
        handle_vertical_monitor(&mut socket, &columns, 3);
    } else {
        let aspect_ratio = f64::from(logical.width) / f64::from(logical.height);
        let max_cols = if aspect_ratio >= 21.0 / 9.0 { 3 } else { 2 };
        handle_horizontal_monitor(
            &mut socket,
            &columns,
            window,
            f64::from(logical.width),
            max_cols,
        );
    }
}
