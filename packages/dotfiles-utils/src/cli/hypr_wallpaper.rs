use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs, cmd, cmd_output, wallpaper, CmdOutput, Monitor, NixInfo,
};
use rand::seq::SliceRandom;
use std::{path::Path, process::Command};

fn swww(swww_args: &[&str], image: &String) {
    let set_wallpapers = || {
        // check if vertical wallpaper exists
        let vertical_image = image.replace("Wallpapers", "WallpapersVertical");

        // check if vertical monitor exists
        let (vertical, horizontal): (Vec<_>, Vec<_>) = Monitor::monitors()
            .into_iter()
            .partition(|m| m.is_vertical());

        if !vertical.is_empty() && Path::new(&vertical_image).exists() {
            let vertical = vertical
                .iter()
                .map(|m| m.name.to_string())
                .collect::<Vec<_>>()
                .join(",");
            Command::new("swww")
                .arg("img")
                .arg("--outputs")
                .arg(vertical)
                .args(swww_args)
                .arg(vertical_image)
                .spawn()
                .expect("failed to execute process");

            let horizontal = horizontal
                .iter()
                .map(|m| m.name.to_string())
                .collect::<Vec<_>>()
                .join(",");
            Command::new("swww")
                .arg("img")
                .arg("--outputs")
                .arg(horizontal)
                .args(swww_args)
                .arg(image)
                .spawn()
                .expect("failed to execute process");
        } else {
            Command::new("swww")
                .arg("img")
                .args(swww_args)
                .arg(image)
                .spawn()
                .expect("failed to execute process");
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
            .to_string()
            // allow setting from a vertical wallpaper
            .replace("WallpapersVertical", "Wallpapers"),
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
            swww(&[], &wallpaper);
            cmd(["killall", "-SIGUSR2", ".waybar-wrapped"])
        }
    } else {
        if !args.no_wallust {
            cmd(["wallust", &random_wallpaper]);
        }

        if cfg!(feature = "hyprland") {
            swww(
                &["--transition-type", &args.transition_type],
                &random_wallpaper,
            );
        }
    }

    wallpaper::wallust_apply_colors();
}
