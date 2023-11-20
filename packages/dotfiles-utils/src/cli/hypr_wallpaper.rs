use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs, cmd, cmd_output, full_path, json, wallpaper, CmdOutput, Monitor,
    NixInfo,
};
use rand::seq::SliceRandom;
use std::{collections::HashMap, path::Path, process::Command};

type WallpaperInfo = HashMap<String, Option<HashMap<String, serde_json::Value>>>;

fn swww_crop(swww_args: &[&str], image: &String) {
    let set_wallpapers = || {
        // write image path to ~/.cache/current_wallpaper
        std::fs::write(full_path("~/.cache/current_wallpaper"), image)
            .expect("failed to write ~/.cache/current_wallpaper");

        // convert image to path
        let image = Path::new(image);
        let fname = image
            .file_name()
            .expect("invalid image path")
            .to_str()
            .unwrap();

        let crops: WallpaperInfo = json::load(
            full_path("~/Pictures/Wallpapers/wallpapers.json")
                .to_str()
                .unwrap(),
        );

        match crops.get(fname) {
            Some(Some(geometry)) => Monitor::monitors().iter().for_each(|m| {
                let ratio_str = format!("{}x{}", m.width, m.height);

                if let Some(serde_json::Value::String(geometry)) = geometry.get(&ratio_str) {
                    // use custom swww-crop defined in wallpaper.nix
                    Command::new("swww-crop")
                        .arg(image)
                        .arg(geometry)
                        .arg(&m.name)
                        .args(swww_args)
                        .spawn()
                        .expect("failed to set wallpaper");
                }
            }),
            _ => {
                Command::new("swww")
                    .arg("img")
                    .args(swww_args)
                    .arg(image)
                    .spawn()
                    .expect("failed to execute process");
            }
        }
    };

    let is_daemon_running = !cmd_output(["swww", "query"], CmdOutput::Stderr)
        .first()
        .unwrap_or(&"".to_string())
        .starts_with("Error");

    if is_daemon_running {
        set_wallpapers();
    } else {
        // FIXME: weird race condition with swww init, need to sleep for a second
        // https://github.com/Horus645/swww/issues/144

        // sleep for a second
        std::thread::sleep(std::time::Duration::from_secs(1));

        let swww_init = Command::new("swww")
            .arg("init")
            .status()
            .expect("failed to execute swww init");

        // equivalent of bash &&
        if swww_init.success() {
            set_wallpapers();
        }
    }
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    let random_wallpaper = match args.image {
        Some(image) => std::fs::canonicalize(image)
            .unwrap()
            .to_str()
            .unwrap()
            .to_string(),
        None => wallpaper::all()
            .choose(&mut rand::thread_rng())
            // use fallback image if not available
            .unwrap_or(&NixInfo::before().fallback)
            .to_string(),
    };

    if args.reload {
        let wallpaper = wallpaper::current().unwrap_or(random_wallpaper);

        if !args.no_wallust {
            cmd(["wallust", &wallpaper])
        }

        if cfg!(feature = "hyprland") {
            swww_crop(&[], &wallpaper);
            cmd(["killall", "-SIGUSR2", ".waybar-wrapped"])
        }
    } else {
        if !args.no_wallust {
            cmd(["wallust", &random_wallpaper]);
        }

        if cfg!(feature = "hyprland") {
            swww_crop(
                &["--transition-type", &args.transition_type],
                &random_wallpaper,
            );
        }
    }

    wallpaper::wallust_apply_colors();
}
