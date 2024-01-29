use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs,
    cmd, full_path,
    monitor::Monitor,
    nixinfo::NixInfo,
    wallpaper::{self, WallInfo},
    wallust, WAYBAR_CLASS,
};
use std::{collections::HashMap, path::Path, process::Command};

fn get_wallpaper_info(image: &String) -> Option<WallInfo> {
    let wallpapers_json = full_path("~/Pictures/Wallpapers/wallpapers.json");
    if !wallpapers_json.exists() {
        return None;
    }

    // convert image to path
    let image = Path::new(image);
    let fname = image
        .file_name()
        .expect("invalid image path")
        .to_str()
        .expect("could not convert image path to str");

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_json).expect("could not open wallpapers.json"),
    );
    let mut crops: HashMap<String, WallInfo> =
        serde_json::from_reader(reader).expect("could not parse wallpapers.json");
    crops.remove(fname)
}

fn swww_crop(swww_args: &[&str], image: &String, wall_info: &Option<WallInfo>) {
    let set_wallpapers = || {
        // write image path to ~/.cache/current_wallpaper
        std::fs::write(full_path("~/.cache/current_wallpaper"), image)
            .expect("failed to write ~/.cache/current_wallpaper");

        match wall_info {
            Some(info) => Monitor::monitors().iter().for_each(|m| {
                match info.get_geometry(m.width, m.height) {
                    Some(geometry) => {
                        // use custom swww-crop defined in wallpaper.nix
                        Command::new("swww-crop")
                            .arg(image)
                            .arg(geometry)
                            .arg(&m.name)
                            .args(swww_args)
                            .spawn()
                            .expect("failed to set wallpaper");
                    }
                    None => {
                        Command::new("swww")
                            .arg("img")
                            .args(swww_args)
                            .arg(image)
                            .spawn()
                            .expect("failed to execute process");
                    }
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

    set_wallpapers();
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    let random_wallpaper = match args.image {
        Some(image) => std::fs::canonicalize(image)
            .expect("invalid image path")
            .to_str()
            .expect("could not convert image path to str")
            .to_string(),
        None => {
            if full_path("~/.cache/wallust/nix.json").exists() {
                wallpaper::random()
            } else {
                NixInfo::before().fallback
            }
        }
    };

    let wallpaper = if args.reload {
        wallpaper::current().unwrap_or(random_wallpaper)
    } else {
        random_wallpaper
    };

    let wallpaper_info = get_wallpaper_info(&wallpaper);

    // use colorscheme set from nix if available
    if let Some(cs) = NixInfo::before().colorscheme {
        wallust::apply_theme(cs.as_str());
    } else {
        wallust::from_wallpaper(&wallpaper_info, &wallpaper);
    }

    if cfg!(feature = "hyprland") {
        if args.reload {
            swww_crop(&[], &wallpaper, &wallpaper_info);
            cmd(["killall", "-SIGUSR2", WAYBAR_CLASS]);
        } else {
            swww_crop(
                &["--transition-type", &args.transition_type],
                &wallpaper,
                &wallpaper_info,
            );
        }
    }

    wallust::apply_colors();
}
