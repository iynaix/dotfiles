use clap::Parser;
use dotfiles_utils::{cli::HyprWallpaperArgs, cmd, cmd_output, wallpaper, CmdOutput, NixInfo};
use rand::seq::SliceRandom;
use std::process::Command;

fn swww(swww_args: &[&str]) {
    let is_daemon_running = !cmd_output(["swww", "query"], CmdOutput::Stderr)
        .first()
        .unwrap_or(&"".to_string())
        .starts_with("Error");

    if is_daemon_running {
        Command::new("swww")
            .args(swww_args)
            .spawn()
            .expect("failed to execute process");
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
            Command::new("swww")
                .args(swww_args)
                .spawn()
                .expect("failed to execute process");
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
            swww(&["img", &wallpaper]);
            cmd(["killall", "-SIGUSR2", ".waybar-wrapped"])
        }
    } else {
        if !args.no_wallust {
            cmd(["wallust", &random_wallpaper]);
        }

        if cfg!(feature = "hyprland") {
            swww(&[
                "img",
                "--transition-type",
                &args.transition_type,
                &random_wallpaper,
            ]);
        }
    }

    wallpaper::wallust_apply_colors();
}
