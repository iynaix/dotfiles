use clap::{ArgGroup, CommandFactory, Parser};
use dotfiles::{
    full_path, generate_completions, iso8601_filename, nixinfo::NixInfo, wallpaper, ShellCompletion,
};
use hyprland::dispatch;
use hyprland::{
    data::Monitor,
    dispatch::{Dispatch, DispatchType},
    shared::HyprDataActive,
};
use itertools::Itertools;
use std::{collections::HashSet, path::PathBuf};

#[allow(clippy::struct_excessive_bools)]
#[derive(Parser, Debug)]
#[command(
    name = "hypr-wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
#[command(group(
    ArgGroup::new("exclusive_group")
        .args(&["reload", "pqiv", "history", "image_or_dir"])
        .multiple(false)
))]
pub struct HyprWallpaperArgs {
    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,

    #[arg(long, action, help = "Reload current wallpaper")]
    pub reload: bool,

    #[arg(
        long,
        action,
        visible_alias = "rofi",
        help = "Show wallpaper selector with pqiv",
        exclusive = true
    )]
    pub pqiv: bool,

    #[arg(long, action, help = "Show wallpaper history selector with rofi")]
    pub history: bool,

    #[arg(long, action, help = "Do not save history")]
    pub no_history: bool,

    #[arg(long, action, help = "Transition type for swww")]
    pub transition: Option<String>,

    // optional image to use, uses a random one otherwise
    #[arg(
        action,
        value_hint = clap::ValueHint::AnyPath,
        value_name = "PATH",
        help = "An image or directory path",
        // add = ArgValueCandidates::new(get_wallpaper_files)
    )]
    pub image_or_dir: Option<PathBuf>,
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

    for path in std::fs::read_dir(&wallpaper_history)
        .expect("failed to read wallpaper_history directory")
        .filter_map(|entry| entry.ok().map(|e| e.path()))
        .sorted_by(|a, b| b.file_name().cmp(&a.file_name()))
        // ignore the current wallpaper
        .skip(1)
    {
        if let Ok(resolved) = std::fs::read_link(&path) {
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
            .collect_vec()
            .join(" ")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}

fn write_wallpaper_history(wallpaper: &str) {
    // write the image as a timestamp to a wallpaper_history directory
    let wallpaper_history = full_path("~/Pictures/wallpaper_history");
    std::fs::create_dir_all(&wallpaper_history)
        .expect("failed to create wallpaper_history directory");

    let target = wallpaper_history.join(iso8601_filename());
    std::os::unix::fs::symlink(wallpaper, target)
        .expect("unable to create wallpaper history symlink");
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions("hypr-wallpaper", &mut HyprWallpaperArgs::command(), &shell);
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

    let wallpaper = if args.reload {
        wallpaper::current()
    } else {
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
                    NixInfo::new().fallback
                }
            }
        };

        // write current wallpaper to $XDG_RUNTIME_DIR/current_wallpaper
        let _ = std::fs::write(
            dirs::runtime_dir()
                .expect("could not get $XDG_RUNTIME_DIR")
                .join("current_wallpaper"),
            &random_wallpaper,
        );

        random_wallpaper
    };

    wallpaper::set(&wallpaper, &args.transition);

    if !args.reload && !args.no_history {
        write_wallpaper_history(&wallpaper);
    }
}
