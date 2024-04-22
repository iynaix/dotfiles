use std::process::Stdio;

use dotfiles_utils::{
    execute_wrapped_process, full_path, json, monitor::Monitor, nixinfo::NixInfo,
};
use execute::Execute;

fn main() {
    execute_wrapped_process("waybar", |process| {
        execute::command_args!("killall", "-q", process)
            .execute()
            .ok();
    });

    // add / remove persistent workspaces config to waybar config before launching
    let config_path = full_path("~/.config/waybar/config.jsonc");
    let config_path = config_path
        .to_str()
        .expect("could not convert waybar config path to str");

    if cfg!(feature = "hyprland") {
        let mut cfg: serde_json::Value = json::load(config_path)
            .unwrap_or_else(|_| panic!("unable to read waybar config at {config_path}"));

        if let NixInfo {
            persistent_workspaces: Some(true),
            ..
        } = NixInfo::before()
        {
            let rearranged_workspaces = Monitor::rearranged_workspaces();

            cfg["hyprland/workspaces"]["persistent-workspaces"] =
                serde_json::to_value(rearranged_workspaces)
                    .expect("failed to convert rearranged workspaces to json");
        } else {
            let hyprland_workspaces = cfg["hyprland/workspaces"]
                .as_object_mut()
                .expect("invalid hyprland workspaces");
            hyprland_workspaces.remove("persistent-workspaces");

            cfg["hyprland/workspaces"] = serde_json::to_value(hyprland_workspaces)
                .expect("failed to convert hyprland workspaces to json");
        }

        // write waybar_config back to waybar_config_file as json
        json::write(config_path, &cfg).expect("failed to write updated waybar config");
    }

    // open waybar in the background
    execute::command!("waybar")
        .stdout(Stdio::null())
        .spawn()
        .expect("failed to execute waybar");
}
