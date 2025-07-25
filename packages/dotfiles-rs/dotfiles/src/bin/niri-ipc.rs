use itertools::Itertools;
use niri_ipc::{Action, Event, Request, Response, WorkspaceReferenceArg, socket::Socket};

fn main() {
    let mut socket = Socket::connect().expect("failed to connect to niri socket");
    // use separate socket instance as read_events() takes ownership
    let mut command_socket = Socket::connect().expect("failed to connect to niri socket");

    let reply = socket
        .send(Request::EventStream)
        .expect("failed to send EventStream request");

    if matches!(reply, Ok(Response::Handled)) {
        let mut read_event = socket.read_events();
        while let Ok(event) = read_event() {
            #[allow(clippy::single_match)]
            match event {
                Event::WorkspacesChanged { workspaces } => {
                    let by_monitor = workspaces
                        .iter()
                        .filter(|wksp| wksp.output.is_some() && wksp.name.is_some())
                        .sorted_by_key(|wksp| wksp.output.clone())
                        .chunk_by(|wksp| wksp.output.clone().unwrap_or_default());

                    for (_, wksps) in &by_monitor {
                        let wksps: Vec<_> = wksps.collect();

                        let by_idx: Vec<_> = wksps.iter().sorted_by_key(|wksp| wksp.idx).collect();
                        let by_name: Vec<_> = wksps
                            .iter()
                            .sorted_by_key(|wksp| {
                                wksp.name.as_ref().map_or_else(
                                    // shouldn't trigger since it's already previously filtered out
                                    || panic!("workspace name is None!"),
                                    |name| {
                                        name.replace('W', "").parse::<u8>().unwrap_or_else(|_| {
                                            panic!("failed to parse workspace name: {name}")
                                        })
                                    },
                                )
                            })
                            .collect();

                        if by_idx != by_name {
                            for (wksp, target) in by_name.iter().zip(by_idx.iter()) {
                                println!("{:?} => {}", wksp.name, target.idx);

                                command_socket
                                    .send(Request::Action(Action::MoveWorkspaceToIndex {
                                        index: target.idx.into(),
                                        reference: Some(WorkspaceReferenceArg::Id(wksp.id)),
                                    }))
                                    .expect("failed to send MoveWorkspaceToIndex request")
                                    .ok();
                            }
                        }
                    }
                }
                _ => {}
            }
        }
    }
}
