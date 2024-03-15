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
use rayon::prelude::*;
use std::path::Path;

fn get_wallpaper_info(image: &String) -> Option<WallInfo> {
    let wallpapers_csv = full_path("~/Pictures/Wallpapers/wallpapers.csv");
    if !wallpapers_csv.exists() {
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
        std::fs::File::open(wallpapers_csv).expect("could not open wallpapers.csv"),
    );

    let mut rdr = csv::Reader::from_reader(reader);
    rdr.deserialize::<WallInfo>()
        .flatten()
        .find(|line| line.filename == fname)
}

fn swww_crop(swww_args: &[&str], image: &String, wall_info: &Option<WallInfo>) {
    // write image path to ~/.cache/current_wallpaper
    std::fs::write(full_path("~/.cache/current_wallpaper"), image)
        .expect("failed to write ~/.cache/current_wallpaper");

    // gather all the wallpaper args for each monitor if possible
    let wallpaper_args = wall_info.as_ref().map_or(Vec::new(), |info| {
        Monitor::monitors()
            .into_iter()
            .filter_map(|m| {
                info.get_geometry(m.width, m.height).map(|geometry| {
                    [
                        geometry.to_string(),
                        format!("{}x{}", m.width, m.height),
                        m.name,
                    ]
                })
            })
            .collect::<Vec<_>>()
    });

    // no monitor args, set wallpaper as is for all monitors
    if wallpaper_args.is_empty() {
        execute::command_args!("swww", "img")
            .args(swww_args)
            .arg(image)
            .execute()
            .expect("failed to set wallpaper");
    } else {
        // set wallpaper for each monitor in parallel with threads
        wallpaper_args.par_iter().for_each(|monitor_args| {
            let swww_args: Vec<_> = swww_args
                .iter()
                .map(std::string::ToString::to_string)
                .collect();

            execute::command_args!("swww-crop")
                .arg(image)
                .args(monitor_args)
                .args(swww_args)
                .execute()
                .expect("failed to set wallpaper");
        });
    }
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

    // do wallust earlier to create the necessary templates
    wallust::apply_colors();

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
}
