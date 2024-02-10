use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs,
    execute_wrapped_process, full_path,
    monitor::Monitor,
    nixinfo::NixInfo,
    wallpaper::{self, WallInfo},
    wallust,
};
use execute::Execute;
use rand::seq::SliceRandom;
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
                        // using rust for the piping the images from imagemagick to swww seeems to be really slow?
                        Command::new("swww-crop")
                            .arg(image)
                            .arg(geometry)
                            .arg(&m.name)
                            .args(swww_args)
                            .spawn()
                            .expect("failed to set wallpaper");
                    }
                    None => {
                        execute::command_args!("swww", "img")
                            .args(swww_args)
                            .arg(image)
                            .execute()
                            .expect("failed to set wallpaper");
                    }
                }
            }),
            _ => {
                execute::command_args!("swww", "img")
                    .args(swww_args)
                    .arg(image)
                    .execute()
                    .expect("failed to set wallpaper");
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
        wallust::apply_theme(&cs);
    } else {
        wallust::from_wallpaper(&wallpaper_info, &wallpaper);
    }

    if cfg!(feature = "hyprland") {
        if args.reload {
            swww_crop(&[], &wallpaper, &wallpaper_info);
            execute_wrapped_process("waybar", |process| {
                execute::command_args!("killall", "-SIGUSR2", process)
                    .execute()
                    .ok();
            });
        } else {
            // choose a random transition, taken from ZaneyOS
            // https://gitlab.com/Zaney/zaneyos/-/blob/main/config/scripts/wallsetter.nix
            let transition = vec![
                vec![
                    "--transition-type",
                    "wave",
                    "--transition-angle",
                    "120",
                    "--transition-step",
                    "30",
                ],
                vec![
                    "--transition-type",
                    "wipe",
                    "--transition-angle",
                    "30",
                    "--transition-step",
                    "30",
                ],
                vec!["--transition-type", "center", "--transition-step", "30"],
                vec![
                    "--transition-type",
                    "outer",
                    "--transition-pos",
                    "0.3,0.8",
                    "--transition-step",
                    "30",
                ],
                vec![
                    "--transition-type",
                    "wipe",
                    "--transition-angle",
                    "270",
                    "--transition-step",
                    "30",
                ],
            ];
            let transition = transition
                .choose(&mut rand::thread_rng())
                .expect("could not choose transition");

            swww_crop(transition, &wallpaper, &wallpaper_info);
        }
    }

    wallust::apply_colors();
}
