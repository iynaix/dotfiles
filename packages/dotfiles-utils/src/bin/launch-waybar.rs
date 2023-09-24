use dotfiles_utils::{cmd, load_json_file, write_json_file, Monitor, NixInfo};
use std::process::Command;

fn main() {
    cmd(&["killall", "-q", ".waybar-wrapped"]);

    // add / remove persistent workspaces config to waybar config before launching
    let mut waybar_config_path = dirs::cache_dir().unwrap_or_default();
    waybar_config_path.push("wallust/waybar.jsonc");

    let mut waybar_css_path = dirs::cache_dir().unwrap_or_default();
    waybar_css_path.push("wallust/waybar.css");

    let mut waybar_config: serde_json::Value =
        load_json_file(&waybar_config_path).expect("failed to read waybar.jsonc");

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
    write_json_file(&waybar_config_path, &waybar_config).expect("failed to write waybar.jsonc");

    // open waybar in the background

    Command::new("waybar")
        .args([
            "--config",
            waybar_config_path.to_str().unwrap(),
            "--style",
            waybar_css_path.to_str().unwrap(),
        ])
        .spawn()
        .expect("failed to execute waybar");

    std::process::exit(0);
}
