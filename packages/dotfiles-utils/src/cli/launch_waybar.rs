use dotfiles_utils::{cmd, full_path, json, monitor::Monitor, nixinfo::NixInfo, WAYBAR_CLASS};
use std::process::Command;

fn main() {
    cmd(["killall", "-q", WAYBAR_CLASS]);

    // add / remove persistent workspaces config to waybar config before launching
    let config_path = full_path("~/.config/waybar/config");
    let config_path = config_path
        .to_str()
        .expect("could not convert config path to str");

    if cfg!(feature = "hyprland") {
        let mut cfg: serde_json::Value = json::load(config_path);

        if NixInfo::before().persistent_workspaces {
            let rearranged_workspaces = Monitor::rearranged_workspaces();

            cfg["hyprland/workspaces"]["persistent-workspaces"] =
                serde_json::to_value(rearranged_workspaces).expect("failed to convert to json");
        } else {
            let hyprland_workspaces = cfg["hyprland/workspaces"]
                .as_object_mut()
                .expect("invalid hyprland workspaces");
            hyprland_workspaces.remove("persistent-workspaces");

            cfg["hyprland/workspaces"] =
                serde_json::to_value(hyprland_workspaces).expect("failed to convert to json");
        }

        // write waybar_config back to waybar_config_file as json
        json::write(config_path, &cfg);
    }

    // open waybar in the background
    Command::new("waybar")
        .spawn()
        .expect("failed to execute waybar");

    if NixInfo::before().waybar_hidden {
        std::thread::sleep(std::time::Duration::from_millis(500));

        // hide waybar via SIGUSR1
        Command::new("killall")
            .arg("-SIGUSR1")
            .arg(WAYBAR_CLASS)
            .status()
            .expect("Failed to execute killall");
    }
}
