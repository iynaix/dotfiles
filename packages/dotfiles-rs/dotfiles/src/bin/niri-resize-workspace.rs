use clap::{CommandFactory, Parser};
use common::niri::resize_workspace;
use dotfiles::{cli::NiriResizeWorkspaceArgs, generate_completions};
use niri_ipc::{Request, Response, socket::Socket};

fn main() {
    let args = NiriResizeWorkspaceArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions(
            "niri-resize-workspace",
            &mut NiriResizeWorkspaceArgs::command(),
            &shell,
        );
        std::process::exit(0);
    }

    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let Ok(Response::Windows(windows)) = socket
        .send(Request::Windows)
        .expect("failed to send Windows")
    else {
        return;
    };

    let Ok(Response::Workspaces(workspaces)) = socket
        .send(Request::Workspaces)
        .expect("failed to send Workspaces")
    else {
        return;
    };

    let Some(focused_window) = windows.iter().find(|win| win.is_focused) else {
        return;
    };

    let Some(wksp_id) = args.workspace.map_or_else(
        || focused_window.workspace_id,
        |wksp_no| {
            workspaces
                .iter()
                .find(|wksp| wksp.name == Some(format!("W{wksp_no}")))
                .map(|wksp| wksp.id)
        },
    ) else {
        return;
    };

    resize_workspace(wksp_id, Some(focused_window), windows.clone(), workspaces);
}
