use clap::Parser;
use color_eyre::eyre::Result;
use common::{is_hyprland, is_umbriel};
use dotfiles::cli::FocusOrRunArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use serde::Deserialize;
use std::process::Stdio;

#[derive(Debug, Deserialize)]
pub struct UmbrielWindows {
    pub id: String,
    pub title: String,
}

fn main() -> Result<()> {
    let args = FocusOrRunArgs::parse();

    if is_hyprland() {
        let clients = Clients::get()?;

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
                .execute()?;
                return Ok(());
            }
        }
    }

    if is_umbriel() {
        let umbriel_cmd = execute::command_args!("umbriel", "windows", "--json")
            .stdout(Stdio::piped())
            .execute_output()?;
        let umbriel_json = String::from_utf8(umbriel_cmd.stdout)?;
        let windows: Vec<UmbrielWindows> = serde_json::from_str(&umbriel_json)?;

        for win in windows {
            if win.title.contains(&args.title) {
                execute::command_args!("umbriel", "msg", format!("window-focus-warp:{}", win.id))
                    .execute_output()?;
                return Ok(());
            }
        }
    }

    std::process::Command::new("sh")
        .arg("-c")
        .arg(args.command)
        .status()?;

    Ok(())
}
