use clap::Parser;
use color_eyre::eyre::Result;
use common::is_hyprland;
use dotfiles::cli::EmacsLauncherArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use std::process::Command;

fn execute_emacs_command(elisp: &str) -> Result<()> {
    let cmd = format!(r"(progn (select-frame-set-input-focus (selected-frame)) {elisp})");

    println!("{cmd}");

    Command::new("emacsclient")
        .args(["-n", "-e", &cmd])
        .status()?;

    Ok(())
}

fn main() -> Result<()> {
    let args = EmacsLauncherArgs::parse();

    // switch to emacs window
    if is_hyprland() {
        let clients = Clients::get()?;

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
                .execute()?;
            }
        }
    }

    std::thread::sleep(std::time::Duration::from_millis(500));

    execute_emacs_command(&args.elisp)
}
