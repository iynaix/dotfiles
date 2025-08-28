use common::{
    CommandUtf8, is_waybar_hidden,
    niri::{MonitorExt, WindowExt, resize_workspace},
    nixjson::{NixJson, NixMonitor},
    wallpaper,
};
use dotfiles::cli::MonitorExtend;
use execute::Execute;
use itertools::Itertools;
use niri_ipc::{
    Action, Event, Request, Response, Window, WindowLayout, Workspace, WorkspaceReferenceArg,
    socket::Socket,
    state::{EventStreamState, EventStreamStatePart},
};
use std::{
    collections::{HashMap, HashSet},
    time::{Duration, SystemTime},
};

const TOTAL_WORKSPACES: usize = 10;

fn debounce(interval: Duration, debounce_fn: impl FnOnce()) {
    let lock_file = dirs::runtime_dir()
        .expect("unable to get runtime dir")
        .join("wallpaper.lock");

    if lock_file.exists() {
        let metadata =
            std::fs::metadata(&lock_file).expect("unable to get wallpaper.lock metadata");
        let last_run_time = metadata
            .modified()
            .expect("unable to get wallpaper.lock mtime");
        let current_time = SystemTime::now();

        if let Ok(elapsed) = current_time.duration_since(last_run_time)
            && elapsed < interval
        {
            let wait_time = interval.saturating_sub(elapsed);
            eprintln!(
                "Script was run too recently. Please wait {} seconds.",
                wait_time.as_secs_f64()
            );
            std::process::exit(1);
        }
    }

    // update lock file with current time
    std::fs::File::create(lock_file).expect("unable to create wallpaper.lock");

    debounce_fn();
}

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
    let has_unknown_monitors = workspaces.iter().any(|wksp| {
        if let Some(mon) = wksp.output.as_ref() {
            return !nix_info_monitors.iter().any(|nix_mon| nix_mon.name == *mon);
        }
        false
    });

    // new monitor added, redistribute workspaces
    let wksps = if has_unknown_monitors {
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

    if has_unknown_monitors {
        focus_workspaces(nix_info_monitors);
    } else {
        renumber_workspaces(&by_monitor);

        // reload the wallpaper (which also reloads waybar)
        // only run at most once per 5s
        debounce(Duration::from_secs(5), || wallpaper::reload(None));
    }
}

fn waybar_main_pid() -> Option<String> {
    execute::command_args!("pidof", "waybar")
        .execute_stdout_lines()
        .expect("unable to get pidof waybar")
        .first()
        .cloned()
}

fn handle_overview_changed(is_open: bool, waybar_initial_hidden: &mut bool) {
    let waybar_hidden = is_waybar_hidden();

    // get the PID of the main waybar instance via systemd
    if is_open {
        // write the initial waybar state
        *waybar_initial_hidden = waybar_hidden;

        // hide main waybar if needed
        if !waybar_hidden && let Some(waybar_pid) = waybar_main_pid() {
            execute::command_args!("kill", "-SIGUSR1", waybar_pid)
                .execute()
                .expect("unable to toggle waybar");
        }
    } else {
        // show waybar if needed
        if !*waybar_initial_hidden {
            execute::command_args!("pkill", "-SIGUSR1", ".waybar-wrapped")
                .execute()
                .expect("unable to toggle waybar");
        }
    }
}

fn resize_workspace_from_state(
    workspace_id: u64,
    window: Option<&Window>,
    state: &EventStreamState,
) {
    resize_workspace(
        workspace_id,
        window,
        state.windows.windows.values().cloned(),
        state.workspaces.workspaces.values().cloned(),
    );
}

fn handle_window_closed(state: &EventStreamState, prev_windows: &HashMap<u64, Window>) {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    // figure out which window was closed
    let prev_ids: HashSet<_> = prev_windows.keys().collect();
    let curr_ids: HashSet<_> = state.windows.windows.keys().collect();
    let prev_win = prev_ids
        .difference(&curr_ids)
        .next()
        .and_then(|id| prev_windows.get(id));

    // closing a floating window, ignore
    if prev_win.is_some_and(|win| win.is_floating) {
        return;
    }

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

    resize_workspace_from_state(focused_workspace.id, Some(&focused_window), state);
}

fn handle_window_layouts_changed(
    changes: &[(u64, WindowLayout)],
    state: &EventStreamState,
    prev_windows: &HashMap<u64, Window>,
) {
    let same_workspace_changes = changes
        .iter()
        .filter_map(|(id, _)| {
            let prev_win = prev_windows.get(id)?;
            let curr_win = state.windows.windows.get(id)?;

            // different workspace
            if prev_win.workspace_id.is_none() || prev_win.workspace_id != curr_win.workspace_id {
                return None;
            }

            // workspace_id is Some due to check above
            Some((
                prev_win.workspace_id.unwrap_or_default(),
                prev_win,
                curr_win,
            ))
        })
        .collect_vec();

    if same_workspace_changes.is_empty() {
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

    for (wksp_id, prev_win, curr_win) in same_workspace_changes {
        let prev_cols = prev_windows
            .values()
            .filter(|win| win.workspace_id == Some(wksp_id))
            .filter_map(WindowExt::col)
            .max()
            .unwrap_or_default();

        let curr_cols = state
            .windows
            .windows
            .values()
            .filter(|win| win.workspace_id == Some(wksp_id))
            .filter_map(WindowExt::col)
            .max()
            .unwrap_or_default();

        // check for coming out of fullscreen
        if prev_cols == curr_cols {
            // find the workspace
            let Some(wksp) = workspaces.iter().find(|wksp| wksp.id == wksp_id) else {
                continue;
            };

            let Some(mon) = monitors
                .values()
                .find(|mon| Some(mon.name.clone()) == wksp.output)
            else {
                continue;
            };

            if let Some((mon_w, mon_h)) = mon.dimensions() {
                let (prev_w, prev_h) = prev_win.layout.window_size;
                let (curr_w, curr_h) = curr_win.layout.window_size;

                if prev_w * prev_h == mon_w * mon_h && (curr_w != prev_w || curr_h != prev_h) {
                    resize_workspace_from_state(wksp_id, Some(curr_win), state);
                }
            }
        }
        // adding or removing a column
        else {
            resize_workspace_from_state(wksp_id, Some(curr_win), state);
        }
    }
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
            resize_workspace_from_state(wksp_id, Some(window), state);
        }
    } else {
        // check for window moving to another workspace
        for (id, prev_win) in prev_windows {
            if let Some(curr_win) = curr_windows.get(id)
                && curr_win.workspace_id != prev_win.workspace_id
            {
                if let Some(wksp_id) = prev_win.workspace_id {
                    resize_workspace_from_state(wksp_id, None, state);
                }
                if let Some(wksp_id) = curr_win.workspace_id {
                    resize_workspace_from_state(wksp_id, Some(window), state);
                }
                break;
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

                            handle_overview_changed(is_open, &mut waybar_initial_hidden);
                        }
                        Event::WindowOpenedOrChanged { window } => {
                            handle_window_opened_or_changed(&window, &prev_windows, &state);
                        }
                        Event::WindowClosed { id: _ } => {
                            handle_window_closed(&state, &prev_windows);
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
