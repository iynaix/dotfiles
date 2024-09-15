use std::process::Stdio;

use dotfiles::{full_path, json, kill_wrapped_process, nixinfo::NixInfo, rearranged_workspaces};

fn main() {
    kill_wrapped_process("waybar", "SIGINT");

    // add / remove persistent workspaces config to waybar config before launching
    let config_path = full_path("~/.config/waybar/config.jsonc");
    let config_path = config_path
        .to_str()
        .expect("could not convert waybar config path to str");

    let mut cfg: serde_json::Value = json::load(config_path)
        .unwrap_or_else(|_| panic!("unable to read waybar config at {config_path}"));

    if let NixInfo {
        waybar_persistent_workspaces: Some(true),
        ..
    } = NixInfo::before()
    {
        cfg["hyprland/workspaces"]["persistentWorkspaces"] =
            serde_json::to_value(rearranged_workspaces())
                .expect("failed to convert rearranged workspaces to json");
    } else {
        let hyprland_workspaces = cfg["hyprland/workspaces"]
            .as_object_mut()
            .expect("invalid hyprland workspaces");
        hyprland_workspaces.remove("persistentWorkspaces");

        cfg["hyprland/workspaces"] = serde_json::to_value(hyprland_workspaces)
            .expect("failed to convert hyprland workspaces to json");
    }

    // write waybar_config back to waybar_config_file as json
    json::write(config_path, &cfg).expect("failed to write updated waybar config");

    // open waybar in the background
    execute::command!("waybar")
        .stdout(Stdio::null())
        .spawn()
        .expect("failed to execute waybar");
}
