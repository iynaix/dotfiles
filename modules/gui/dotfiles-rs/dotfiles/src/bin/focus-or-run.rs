use std::process::Stdio;

use clap::Parser;
use common::{is_hyprland, is_umbriel};
use dotfiles::cli::FocusOrRunArgs;
use execute::Execute;
use hyprland::{data::Clients, shared::HyprData};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct UmbrielWindows {
    pub id: String,
    pub title: String,
}

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

    if is_umbriel() {
        let umbriel_cmd = execute::command_args!("umbriel", "windows", "--json")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("failed to run umbriel workspaces");
        let umbriel_json =
            String::from_utf8(umbriel_cmd.stdout).expect("invalid utf8 from umbriel workspaces");
        let windows: Vec<UmbrielWindows> =
            serde_json::from_str(&umbriel_json).expect("failed to parse json");

        for win in windows {
            if win.title.contains(&args.title) {
                execute::command_args!("umbriel", "msg", format!("window-focus-warp:{}", win.id))
                    .execute_output()
                    .expect("failed to focus window");
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
