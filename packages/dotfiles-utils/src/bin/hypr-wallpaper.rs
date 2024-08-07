use std::io::Write;

use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs,
    execute_wrapped_process, full_path,
    nixinfo::NixInfo,
    wallpaper::{self, get_wallpaper_info},
    wallust,
};
use execute::Execute;

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

    // write wallpaper log
    if !args.reload {
        // append
        let mut wallpaper_log = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(full_path("~/.local/share/wallpapers.log"))
            .expect("unable to open wallpaper log");

        wallpaper_log
            // write timestamp followed by wallpaper
            .write_all(format!("{}|{wallpaper}\n", chrono::Local::now().to_rfc3339()).as_bytes())
            .expect("failed to write wallpaper log");
    }
}
