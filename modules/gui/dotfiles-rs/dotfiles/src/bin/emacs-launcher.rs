use clap::Parser;
use common::is_hyprland;
use dotfiles::cli::EmacsLauncherArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use std::process::Command;

fn execute_emacs_command(elisp: &str) -> Result<(), String> {
    let cmd = format!(r"(progn (select-frame-set-input-focus (selected-frame)) {elisp})");

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

    std::thread::sleep(std::time::Duration::from_millis(500));

    execute_emacs_command(&args.elisp)
}
