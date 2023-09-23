use clap::Parser;
use dirs::cache_dir;
use dotfiles_utils::{
    cmd, get_active_monitors, get_rearranged_workspaces, load_json_file, write_json_file,
};
use std::path::PathBuf;
use std::process::Command;

fn wallust_cache(path: &str) -> PathBuf {
    let mut cache_dir = cache_dir().unwrap_or_default();
    cache_dir.push("wallust");
    cache_dir.push(path);

    cache_dir
}

#[derive(Parser, Debug)]
#[command(name = "launch_waybar", about = "Relaunches waybar")]
struct Args {
    #[arg(
        short,
        long,
        value_name = "CONFIG",
        default_value_os_t = wallust_cache("waybar.jsonc")
    )]
    config: PathBuf,

    #[arg(
        short,
        long,
        value_name = "STYLE",
        default_value_os_t = wallust_cache("waybar.css")
    )]
    style: PathBuf,

    #[arg(long, default_value = "false")]
    persistent_workspaces: bool,
}

fn main() {
    let args = Args::parse();

    cmd(&["killall", "-q", ".waybar-wrapped"]);

    // add / remove persistent workspaces config to waybar config before launching
    let mut waybar_config_path = dirs::cache_dir().unwrap_or_default();
    waybar_config_path.push("wallust/waybar.jsonc");

    let mut waybar_config: serde_json::Value =
        load_json_file(&waybar_config_path).expect("failed to read waybar.jsonc");

    if args.persistent_workspaces {
        let active_monitors = get_active_monitors();
        let rearranged_workspaces = get_rearranged_workspaces(&active_monitors);

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
    Command::new("waybar").args([
        "--config",
        args.config.to_str().unwrap(),
        "--style",
        args.style.to_str().unwrap(),
    ]).spawn().expect("failed to launch waybar");
}
