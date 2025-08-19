use common::{
    CommandUtf8, full_path, is_waybar_hidden,
    nixjson::{NixJson, NixMonitor},
};
use dotfiles::cli::MonitorExtend;
use execute::Execute;
use itertools::Itertools;
use niri_ipc::{
    Action, Event, LogicalOutput, Request, Response,
    SizeChange::SetProportion,
    Transform, Window, WindowLayout, Workspace, WorkspaceReferenceArg,
    socket::Socket,
    state::{EventStreamState, EventStreamStatePart},
};
use std::{collections::HashMap, process::Stdio};

const TOTAL_WORKSPACES: usize = 10;

fn focus_workspaces(nix_info_monitors: &[NixMonitor]) {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let Ok(Response::Windows(windows)) = socket
        .send(Request::Windows)
        .expect("failed to send Windows")
    else {
        panic!("invalid reply for Windows");
    };

    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        panic!("invalid reply for Workspaces");
    };

    // get focused workspace for each monitor
    workspaces
        .iter()
        .filter_map(|wksp| {
            if !wksp.is_active {
                return None;
            }

            // are there any windows on this workspace?
            if windows.iter().any(|win| win.workspace_id == Some(wksp.id)) {
                return None;
            }

            wksp.output.clone()
        })
        // go to default workspace for the monitor
        .for_each(|mon_name| {
            if let Some(nix_mon) = nix_info_monitors
                .iter()
                .find(|nix_mon| nix_mon.name == mon_name)
            {
                let wksp_name = format!("W{}", nix_mon.default_workspace);
                socket
                    .send(Request::Action(Action::FocusWorkspace {
                        reference: WorkspaceReferenceArg::Name(wksp_name),
                    }))
                    .expect("failed to send FocusWorkspace")
                    .ok();
            }
        });
}

fn renumber_workspaces(by_monitor: &HashMap<String, Vec<Workspace>>) {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    for wksps in by_monitor.values() {
        let by_idx: Vec<_> = wksps.iter().sorted_by_key(|wksp| wksp.idx).collect();
        let by_name: Vec<_> = wksps
            .iter()
            .sorted_by_key(|wksp| {
                wksp.name.as_ref().map_or_else(
                    // shouldn't trigger since it's already previously filtered out
                    || panic!("workspace name is None!"),
                    |name| {
                        name.replace('W', "")
                            .parse::<u8>()
                            .unwrap_or_else(|_| panic!("failed to parse workspace name: {name}"))
                    },
                )
            })
            .collect();

        if by_idx != by_name {
            for (wksp, target) in by_name.iter().zip(by_idx.iter()) {
                socket
                    .send(Request::Action(Action::MoveWorkspaceToIndex {
                        index: target.idx.into(),
                        reference: Some(WorkspaceReferenceArg::Id(wksp.id)),
                    }))
                    .expect("failed to send MoveWorkspaceToIndex")
                    .ok();
            }
        }
    }
}

/// distribute the workspaces evenly across all monitors
pub fn distribute_workspaces(
    extend_type: &MonitorExtend,
    current_monitors: &[String],
    nix_monitors: &[NixMonitor],
) -> Vec<Workspace> {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let all_monitors = current_monitors
        .iter()
        // put the nix_monitors first
        .sorted_by_key(|mon_name| {
            let is_base_monitor = nix_monitors.iter().any(|m| m.name == **mon_name);
            (
                match extend_type {
                    MonitorExtend::Primary => is_base_monitor,
                    MonitorExtend::Secondary => !is_base_monitor,
                },
                (*mon_name).to_string(),
            )
        })
        .collect_vec();

    let mut start = 0;
    for (i, mon_name) in all_monitors.iter().enumerate() {
        let len = TOTAL_WORKSPACES / all_monitors.len()
            + usize::from(i < TOTAL_WORKSPACES % all_monitors.len());
        let end = start + len;

        for wksp in start..end {
            socket
                .send(Request::Action(Action::MoveWorkspaceToMonitor {
                    output: (*mon_name).to_string(),
                    reference: Some(WorkspaceReferenceArg::Name(format!("W{}", wksp + 1))),
                }))
                .expect("failed to send MoveWorkspaceToMonitor")
                .ok();
        }
        start += len;
    }

    // return the redistributed workspaces
    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        panic!("invalid reply for Workspaces");
    };
    workspaces
}

fn handle_workspaces_changed(workspaces: &[Workspace], nix_info_monitors: &[NixMonitor]) {
    let has_non_preset_monitors = workspaces.iter().any(|wksp| {
        if let Some(mon) = wksp.output.as_ref() {
            return !nix_info_monitors.iter().any(|nix_mon| nix_mon.name == *mon);
        }
        false
    });

    // new monitor added, redistribute workspaces
    let wksps = if has_non_preset_monitors {
        let monitor_names = workspaces
            .iter()
            .filter_map(|wksp| wksp.output.clone())
            .unique()
            .collect_vec();

        distribute_workspaces(&MonitorExtend::Secondary, &monitor_names, nix_info_monitors)
    } else {
        workspaces.to_vec()
    };

    let by_monitor: HashMap<_, _> = wksps
        .iter()
        .filter(|wksp| wksp.output.is_some() && wksp.name.is_some())
        .sorted_by_key(|wksp| wksp.output.clone())
        .chunk_by(|wksp| wksp.output.clone().unwrap_or_default())
        .into_iter()
        .map(|(mon, wksps)| (mon, wksps.cloned().collect_vec()))
        .collect();

    // common::log!("by_monitor: {by_monitor:?}",);

    if has_non_preset_monitors {
        focus_workspaces(nix_info_monitors);
    } else {
        renumber_workspaces(&by_monitor);

        // reload waybar to clear multiple instances if necessary
        execute::command_args!("pkill", "-SIGUSR2", ".waybar-wrapped")
            .execute()
            .expect("unable to reload waybar");
    }
}

fn waybar_main_pid() -> Option<String> {
    execute::command_args!("pidof", "waybar")
        .execute_stdout_lines()
        .expect("unable to get pidof waybar")
        .first()
        .cloned()
}

fn handle_overview_changed(
    is_open: bool,
    waybar_initial_hidden: &mut bool,
    waybar_overview_pid: &mut Option<u32>,
) {
    let waybar_hidden = is_waybar_hidden();

    // get the PID of the main waybar instance via systemd
    if is_open {
        // write the initial waybar state
        *waybar_initial_hidden = waybar_hidden;

        // hide main waybar if needed
        if !waybar_hidden {
            if let Some(waybar_pid) = waybar_main_pid() {
                execute::command_args!("kill", "-SIGUSR1", waybar_pid)
                    .execute()
                    .expect("unable to toggle waybar");
            }
        }

        // launch new waybar for the overview
        #[allow(clippy::zombie_processes)]
        let waybar_pid = execute::command_args!(
            "waybar",
            "--config",
            full_path("~/.config/waybar/config-overview.jsonc")
        )
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .expect("unable to launch waybar overview");

        *waybar_overview_pid = Some(waybar_pid.id());
    } else {
        // kill the overview waybar
        if let Some(pid) = waybar_overview_pid {
            execute::command_args!("kill", pid.to_string())
                .execute()
                .expect("unable to kill waybar-overview");
        }
        *waybar_overview_pid = None;

        // show waybar if needed
        if !*waybar_initial_hidden {
            execute::command_args!("pkill", "-SIGUSR1", ".waybar-wrapped")
                .execute()
                .expect("unable to toggle waybar");
        }
    }
}

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

fn handle_vertical_monitor(socket: &mut Socket, columns: &[Vec<&Window>], max_rows: usize) {
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
    columns: &[Vec<&Window>],
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

fn resize_workspace(workspace_id: u64, window: Option<&Window>, state: &EventStreamState) {
    let windows = state.windows.windows.values();

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

    let Some(wksp) = state
        .workspaces
        .workspaces
        .values()
        .find(|wksp| wksp.id == workspace_id)
    else {
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
        handle_single_window(&mut socket, wksp_windows[0], &logical);
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

fn handle_window_closed(state: &EventStreamState) {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    // get current workspace
    let Ok(Response::FocusedOutput(Some(focused_output))) = socket
        .send(Request::FocusedOutput)
        .expect("failed to send FocusedOutput")
    else {
        return;
    };

    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        return;
    };

    let Some(focused_workspace) = workspaces
        .iter()
        .find(|wksp| wksp.is_active && wksp.output == Some(focused_output.name.clone()))
    else {
        return;
    };

    // get current focused window, rest of the logic is resizing windows
    let Ok(Response::FocusedWindow(Some(focused_window))) = socket
        .send(Request::FocusedWindow)
        .expect("failed to send FocusedWindow")
    else {
        return;
    };

    resize_workspace(focused_workspace.id, Some(&focused_window), state);
}

fn handle_window_layouts_changed(
    changes: &[(u64, WindowLayout)],
    state: &EventStreamState,
    prev_windows: &HashMap<u64, Window>,
) {
    let workspace_changes: HashMap<_, _> = changes
        .iter()
        .filter_map(|(id, _)| {
            let prev_win = prev_windows.get(id)?;
            let curr_win = state.windows.windows.get(id)?;

            // different workspace
            if prev_win.workspace_id.is_none() || prev_win.workspace_id != curr_win.workspace_id {
                return None;
            }

            let (prev_w, prev_h) = prev_win.layout.window_size;
            let (curr_w, curr_h) = curr_win.layout.window_size;

            if prev_w * prev_h > curr_w * curr_h {
                // workspace_id is Some due to check above
                Some((
                    prev_win.workspace_id.unwrap_or_default(),
                    (id, prev_w, prev_h),
                ))
            } else {
                None
            }
        })
        .collect();

    if workspace_changes.is_empty() {
        return;
    }

    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        return;
    };

    let Ok(Response::Outputs(monitors)) = socket
        .send(Request::Outputs)
        .expect("failed to send Outputs")
    else {
        panic!("invalid reply for Outputs");
    };

    workspace_changes
        .iter()
        .filter_map(|(wksp_id, (win_id, w, h))| {
            // find the workspace
            let wksp = workspaces.iter().find(|wksp| wksp.id == *wksp_id)?;

            // find the monitor
            let mon = monitors
                .values()
                .find(|mon| Some(mon.name.clone()) == wksp.output)?;

            let logical = mon.logical?;

            // is fullscreen
            #[allow(clippy::cast_sign_loss)]
            if logical.width == *w as u32 && logical.height == *h as u32 {
                Some((*wksp_id, win_id))
            } else {
                None
            }
        })
        .for_each(|(wksp_id, win_id)| {
            if let Some(win) = state.windows.windows.get(win_id) {
                resize_workspace(wksp_id, Some(win), state);
            }
        });
}

fn handle_window_opened_or_changed(
    window: &Window,
    prev_windows: &HashMap<u64, Window>,
    state: &EventStreamState,
) {
    let curr_windows: HashMap<u64, _> = state.windows.windows.clone();

    // is a new window, ignore changes
    if curr_windows.len() > prev_windows.len() {
        if let Some(wksp_id) = window.workspace_id {
            resize_workspace(wksp_id, Some(window), state);
        }
    } else {
        // check for window moving to another workspace
        for (id, prev_win) in prev_windows {
            if let Some(curr_win) = curr_windows.get(id) {
                if curr_win.workspace_id != prev_win.workspace_id {
                    if let Some(wksp_id) = prev_win.workspace_id {
                        resize_workspace(wksp_id, None, state);
                    }
                    if let Some(wksp_id) = curr_win.workspace_id {
                        println!("resizing curr workspace: {wksp_id}");
                        resize_workspace(wksp_id, Some(window), state);
                    }
                    break;
                }
            }
        }
    }
}

fn main() {
    let nix_info_monitors = NixJson::new().monitors;

    let mut socket = Socket::connect().expect("failed to connect to niri socket");
    let reply = socket
        .send(Request::EventStream)
        .expect("failed to send EventStream");

    // when event stream is first read, there are always a few initial events, ignore those
    let mut first_workspace_event_skipped = false;
    let mut first_overview_event_skipped = false;

    // track overview waybar pid and initial hidden state when opened
    let mut waybar_initial_hidden = false;
    let mut waybar_overview_pid: Option<u32> = None;

    if matches!(reply, Ok(Response::Handled)) {
        let mut state = EventStreamState::default();
        let mut read_event = socket.read_events();
        loop {
            match read_event() {
                Ok(event) => {
                    let prev_windows = state.windows.windows.clone();

                    state.apply(event.clone());

                    match event {
                        Event::WorkspacesChanged { workspaces } => {
                            if !first_workspace_event_skipped {
                                first_workspace_event_skipped = true;
                                continue;
                            }

                            handle_workspaces_changed(&workspaces, &nix_info_monitors);
                        }
                        Event::OverviewOpenedOrClosed { is_open } => {
                            if !first_overview_event_skipped {
                                first_overview_event_skipped = true;
                                continue;
                            }

                            handle_overview_changed(
                                is_open,
                                &mut waybar_initial_hidden,
                                &mut waybar_overview_pid,
                            );
                        }
                        Event::WindowOpenedOrChanged { window } => {
                            handle_window_opened_or_changed(&window, &prev_windows, &state);
                        }
                        Event::WindowClosed { id: _ } => {
                            handle_window_closed(&state);
                        }
                        Event::WindowLayoutsChanged { changes } => {
                            handle_window_layouts_changed(&changes, &state, &prev_windows);
                        }
                        _ => {}
                    }
                }
                // don't exit on unknown events or errors
                Err(e) => {
                    eprintln!("Event error: {e}");
                }
            }
        }
    }
}
