use common::nixjson::{NixJson, NixMonitor};
use dotfiles::cli::MonitorExtend;
use itertools::Itertools;
use niri_ipc::{
    Action, Event, Request, Response, Workspace, WorkspaceReferenceArg, socket::Socket,
};
use std::collections::HashMap;

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

fn main() {
    let nix_info_monitors = NixJson::new().monitors;

    let mut socket = Socket::connect().expect("failed to connect to niri socket");
    let reply = socket
        .send(Request::EventStream)
        .expect("failed to send EventStream");

    if matches!(reply, Ok(Response::Handled)) {
        let mut read_event = socket.read_events();
        while let Ok(event) = read_event() {
            #[allow(clippy::single_match)]
            match event {
                Event::WorkspacesChanged { workspaces } => {
                    let has_new_monitors = workspaces.iter().any(|wksp| {
                        if let Some(mon) = wksp.output.as_ref() {
                            return !nix_info_monitors.iter().any(|nix_mon| nix_mon.name == *mon);
                        }
                        false
                    });

                    // new monitor added, redistribute workspaces
                    let wksps = if has_new_monitors {
                        let monitor_names = workspaces
                            .iter()
                            .filter_map(|wksp| wksp.output.clone())
                            .unique()
                            .collect_vec();

                        distribute_workspaces(
                            &MonitorExtend::Secondary,
                            &monitor_names,
                            &nix_info_monitors,
                        )
                    } else {
                        workspaces
                    };

                    let by_monitor: HashMap<_, _> = wksps
                        .iter()
                        .filter(|wksp| wksp.output.is_some() && wksp.name.is_some())
                        .sorted_by_key(|wksp| wksp.output.clone())
                        .chunk_by(|wksp| wksp.output.clone().unwrap_or_default())
                        .into_iter()
                        .map(|(mon, wksps)| (mon, wksps.cloned().collect_vec()))
                        .collect();

                    renumber_workspaces(&by_monitor);

                    focus_workspaces(&nix_info_monitors);
                }
                _ => {}
            }
        }
    }
}
