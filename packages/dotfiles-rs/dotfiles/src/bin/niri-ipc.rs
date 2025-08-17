use common::{
    CommandUtf8, full_path, is_waybar_hidden,
    nixjson::{NixJson, NixMonitor},
};
use dotfiles::cli::MonitorExtend;
use execute::Execute;
use itertools::Itertools;
use niri_ipc::{
    Action, Event, Request, Response, Workspace, WorkspaceReferenceArg, socket::Socket,
};
use std::{collections::HashMap, process::Stdio};

const TOTAL_WORKSPACES: usize = 10;

fn focus_workspaces(nix_info_monitors: &[NixMonitor]) {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let Ok(Response::Windows(windows)) = socket
        .send(Request::Windows)
        .expect("failed to send Windows")
    else {
        panic!("unexpected response from niri, should be Windows");
    };

    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        panic!("unexpected response from niri, should be Workspaces");
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
        panic!("unexpected response from niri, should be Workspaces");
    };
    workspaces
}

fn handle_workspaces_changed(workspaces: &[Workspace], nix_info_monitors: &[NixMonitor]) {
    let has_new_monitors = workspaces.iter().any(|wksp| {
        if let Some(mon) = wksp.output.as_ref() {
            return !nix_info_monitors.iter().any(|nix_mon| nix_mon.name == *mon);
        }
        false
    });

    common::log!("has_new_monitors: {has_new_monitors}",);
    common::log!("workspaces: {workspaces:?}",);

    // new monitor added, redistribute workspaces
    let wksps = if has_new_monitors {
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

    common::log!("by_monitor: {by_monitor:?}",);

    // reload waybar to clear multiple instances if necessary
    if has_new_monitors {
        focus_workspaces(nix_info_monitors);

        execute::command_args!("pkill", "-SIGUSR2", ".waybar-wrapped")
            .execute()
            .expect("unable to reload waybar");
    } else {
        renumber_workspaces(&by_monitor);
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
        let mut read_event = socket.read_events();
        loop {
            match read_event() {
                Ok(event) =>
                {
                    #[allow(clippy::single_match)]
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
                        _ => {}
                    }
                }
                // don't exit on unknown events or errors
                Err(e) => {
                    println!("Event error: {e}");
                }
            }
        }
    }
}
