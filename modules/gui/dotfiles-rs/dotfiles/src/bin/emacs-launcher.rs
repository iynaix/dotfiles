use clap::Parser;
use common::{is_hyprland, is_niri};
use dotfiles::cli::EmacsLauncherArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use niri_ipc::{Action, Request, Response, socket::Socket};
use std::process::Command;

fn execute_emacs_command(elisp: &str) -> Result<(), String> {
    let cmd = format!(r#"(progn (select-frame-set-input-focus (selected-frame)) {elisp})"#);

    println!("{cmd}");

    Command::new("emacsclient")
        .args(["-n", "-e", &cmd])
        .status()
        .map_err(|e| e.to_string())
        .and_then(|status| {
            if status.success() {
                Ok(())
            } else {
                Err(format!("emacsclient exited with status {status}"))
            }
        })
}

fn main() -> Result<(), String> {
    let args = EmacsLauncherArgs::parse();

    // switch to emacs window
    if is_hyprland() {
        let clients = Clients::get().expect("could not get clients");

        for client in clients {
            if client.class.contains("Emacs") {
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
                && title.contains("Emacs")
            {
                socket
                    .send(Request::Action(Action::FocusWindow { id: win.id }))
                    .expect("failed to send FocusWindow")
                    .ok();
            }
        }
    }

    std::thread::sleep(std::time::Duration::from_millis(500));

    execute_emacs_command(&args.elisp)
}
