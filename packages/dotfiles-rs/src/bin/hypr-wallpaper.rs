use clap::{CommandFactory, Parser};
use dotfiles::{
    full_path, generate_completions, iso8601_filename, kill_wrapped_process,
    nixinfo::NixInfo,
    wallpaper::{self, get_wallpaper_info},
    wallust, ShellCompletion,
};
use execute::Execute;
use std::path::PathBuf;
use sysinfo::Signal;

#[derive(Parser, Debug)]
#[command(
    name = "hypr-wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
pub struct HyprWallpaperArgs {
    #[arg(long, action, help = "reload current wallpaper")]
    pub reload: bool,

    // optional image to use, uses a random one otherwise
    pub image_or_dir: Option<PathBuf>,

    #[arg(
        long,
        value_enum,
        help = "type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions("hypr-monitors", &mut HyprWallpaperArgs::command(), &shell);
    }

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
        kill_wrapped_process("waybar", Signal::User2);
    }
    execute::command!("swww-crop")
        .arg(&wallpaper)
        .execute()
        .ok();

    if !args.reload {
        // write the image as a timestamp to a wallpaper_history directory
        let wallpaper_history = full_path("~/Pictures/wallpaper_history");
        std::fs::create_dir_all(&wallpaper_history)
            .expect("failed to create wallpaper_history directory");

        let target = wallpaper_history.join(iso8601_filename());

        std::os::unix::fs::symlink(wallpaper, target)
            .expect("unable to create wallpaper history symlink");

        // remove broken symlinks for deleted wallpapers
        for entry in std::fs::read_dir(wallpaper_history)
            .expect("failed to read wallpaper_history directory")
        {
            let path = entry
                .expect("failed to read wallpaper_history directory entry")
                .path();

            if path.is_symlink() && !path.exists() {
                std::fs::remove_file(path).expect("failed to remove broken symlink");
            }
        }
    }
}
