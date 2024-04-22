use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs,
    execute_wrapped_process, filename, full_path,
    nixinfo::NixInfo,
    wallpaper::{self, WallInfo},
    wallust,
};
use execute::Execute;
use std::path::Path;

/// reads the wallpaper info from wallpapers.csv
fn get_wallpaper_info(image: &String) -> Option<WallInfo> {
    let wallpapers_csv = full_path("~/Pictures/Wallpapers/wallpapers.csv");
    if !wallpapers_csv.exists() {
        return None;
    }

    // convert image to path
    let image = Path::new(image);
    let fname = filename(image);

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_csv).expect("could not open wallpapers.csv"),
    );

    let mut rdr = csv::Reader::from_reader(reader);
    rdr.deserialize::<WallInfo>()
        .flatten()
        .find(|line| line.filename == fname)
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    let random_wallpaper = match args.image_or_dir {
        Some(image_or_dir) => {
            if image_or_dir.is_dir() {
                wallpaper::random_from_dir(&image_or_dir)
            } else {
                std::fs::canonicalize(&image_or_dir)
                    .unwrap_or_else(|_| panic!("invalid wallpaper: {image_or_dir:?}"))
                    .to_str()
                    .unwrap_or_else(|| panic!("could not conver {image_or_dir:?} to str"))
                    .to_string()
            }
        }
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

    // write current wallpaper to $XDG_RUNTIME_DIR/current_wallpaper
    std::fs::write(
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("current_wallpaper"),
        &wallpaper,
    )
    .expect("failed to write $XDG_RUNTIME_DIR/current_wallpaper");

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
            execute_wrapped_process("waybar", |process| {
                execute::command_args!("killall", "-SIGUSR2", process)
                    .execute()
                    .ok();
            });
        }
        execute::command!("swww-crop")
            .arg(&wallpaper)
            .execute()
            .ok();
    }
}
