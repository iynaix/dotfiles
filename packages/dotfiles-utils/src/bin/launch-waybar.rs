use dotfiles_utils::{cmd, full_path, json, Monitor, NixInfo};
use std::process::Command;

fn main() {
    cmd(["killall", "-q", ".waybar-wrapped"]);

    // add / remove persistent workspaces config to waybar config before launching
    let waybar_config_path = "~/.cache/wallust/waybar.jsonc";
    let waybar_css_path = "~/.cache/wallust/waybar.css";

    let mut waybar_config: serde_json::Value = json::load(waybar_config_path);

    if NixInfo::from_config().persistent_workspaces {
        let rearranged_workspaces = Monitor::rearranged_workspaces();

        waybar_config["hyprland/workspaces"]["persistent-workspaces"] =
            serde_json::to_value(rearranged_workspaces).expect("failed to convert to json");
    } else {
        let hyprland_workspaces = waybar_config["hyprland/workspaces"]
            .as_object_mut()
            .unwrap();
        hyprland_workspaces.remove("persistent-workspaces");

        waybar_config["hyprland/workspaces"] =
            serde_json::to_value(hyprland_workspaces).expect("failed to convert to json");
    }

    // write waybar_config back to waybar_config_file as json
    json::write(waybar_config_path, &waybar_config);

    // open waybar in the background

    Command::new("waybar")
        .args([
            "--config",
            full_path(waybar_config_path).to_str().unwrap(),
            "--style",
            full_path(waybar_css_path).to_str().unwrap(),
        ])
        .spawn()
        .expect("failed to execute waybar");

    std::process::exit(0);
}
