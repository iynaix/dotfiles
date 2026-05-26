use clap::Parser;
use common::{is_hyprland, is_niri};
use dotfiles::cli::FocusOrRunArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use niri_ipc::{Action, Request, Response, socket::Socket};

fn main() {
    let args = FocusOrRunArgs::parse();

    if is_hyprland() {
        let clients = Clients::get().expect("could not get clients");

        for client in clients {
            if client.title.contains(&args.title) {
                execute::command_args!(
                    "hyprctl",
                    "dispatch",
                    format!(
                        r#"hl.dsp.focus({{ window = "address:{}" }})"#,
                        client.address
                    )
                )
                .execute()
                .expect("failed to focus window");
                return;
            }
        }
    }

    if is_niri() {
        let mut socket = Socket::connect().expect("failed to connect to niri socket");

        let Ok(Response::Windows(windows)) = socket
            .send(Request::Windows)
            .expect("failed to send Windows")
        else {
            panic!("invalid reply for Windows");
        };

        for win in windows {
            if let Some(title) = win.title
                && title.contains(&args.title)
            {
                socket
                    .send(Request::Action(Action::FocusWindow { id: win.id }))
                    .expect("failed to send FocusWindow")
                    .ok();
                return;
            }
        }
    }

    std::process::Command::new("sh")
        .arg("-c")
        .arg(args.command)
        .status()
        .expect("failed to execute command");
}
