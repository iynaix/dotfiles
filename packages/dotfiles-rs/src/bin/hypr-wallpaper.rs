use clap::{CommandFactory, Parser};
use dotfiles::{
    full_path, generate_completions, iso8601_filename,
    nixinfo::NixInfo,
    wallpaper::{self, get_wallpaper_info},
    wallust, ShellCompletion,
};
use execute::Execute;
use hyprland::dispatch;
use hyprland::{
    data::Monitor,
    dispatch::{Dispatch, DispatchType},
    shared::HyprDataActive,
};
use std::{collections::HashSet, path::PathBuf};

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
        action,
        aliases = ["rofi"],
        help = "show wallpaper selector with pqiv",
        exclusive = true
    )]
    pub pqiv: bool,

    #[arg(long, action, help = "show wallpaper history selector with rofi")]
    pub history: bool,

    #[arg(
        long,
        value_enum,
        help = "type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

fn pqiv_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    let mon = Monitor::get_active().expect("could not get active monitor");

    let mut width = f64::from(mon.width) * TARGET_PERCENT;
    let mut height = f64::from(mon.height) * TARGET_PERCENT;

    // handle vertical monitor
    if height > width {
        std::mem::swap(&mut width, &mut height);
    }

    format!("[float;size {} {};center]", width.floor(), height.floor())
}

fn show_pqiv() {
    let pqiv = format!(
        "{} pqiv --shuffle '{}'",
        pqiv_float_rule(),
        &wallpaper::dir().to_str().expect("invalid wallpaper dir")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}

fn show_history() {
    let wallpaper_history = full_path("~/Pictures/wallpaper_history");

    // remove broken and duplicate symlinks
    let mut uniq_history = HashSet::new();
    let mut final_history = Vec::new();
    let mut history: Vec<_> = std::fs::read_dir(&wallpaper_history)
        .expect("failed to read wallpaper_history directory")
        .filter_map(|entry| entry.ok().map(|e| e.path()))
        .collect();
    history.sort_by(|a, b| b.file_name().cmp(&a.file_name()));

    // ignore the current wallpaper
    for path in history.iter().skip(1) {
        if let Ok(resolved) = std::fs::read_link(path) {
            if uniq_history.contains(&resolved) {
                std::fs::remove_file(path).expect("failed to remove duplicate symlink");
            } else {
                uniq_history.insert(resolved.clone());
                final_history.push(path);
            }
        } else {
            std::fs::remove_file(path).expect("failed to remove broken symlink");
        }
    }

    let pqiv = format!(
        "{} pqiv {}",
        pqiv_float_rule(),
        final_history
            .iter()
            .map(|p| format!("'{}'", p.display()))
            .collect::<Vec<_>>()
            .join(" ")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions("hypr-monitors", &mut HyprWallpaperArgs::command(), &shell);
    }

    // show pqiv for selecting wallpaper, via the "w" keybind
    if args.pqiv {
        show_pqiv();
        return;
    }

    // show rofi for selecting wallpaper history
    if args.history {
        show_history();
        return;
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
    }
}
