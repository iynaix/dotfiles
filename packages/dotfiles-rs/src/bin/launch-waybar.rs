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
    } = NixInfo::new()
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
    let mut waybar = execute::command!("waybar");

    let waybar_logging = false;
    if waybar_logging {
        let waybar_log =
            std::fs::File::create("/tmp/waybar.log").expect("failed to create waybar log file");

        waybar
            .arg("--log-level")
            .arg("info")
            .stdout(Stdio::from(
                waybar_log
                    .try_clone()
                    .expect("failed to clone waybar log file"),
            ))
            .stderr(Stdio::from(waybar_log));
    } else {
        waybar.stdout(Stdio::null()).stderr(Stdio::null());
    }

    waybar.spawn().expect("failed to execute waybar");
}
