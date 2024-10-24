use clap::{ArgGroup, CommandFactory, Parser};
use dotfiles::{full_path, generate_completions, wallpaper, ShellCompletion};
use hyprland::dispatch;
use hyprland::{
    data::Monitor,
    dispatch::{Dispatch, DispatchType},
    shared::HyprDataActive,
};
use itertools::Itertools;
use std::collections::HashMap;
use std::path::PathBuf;

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
    pub skip_history: bool,

    #[arg(long, action, help = "Do not resize or set wallpapers")]
    pub skip_wallpaper: bool,

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
    let history = wallpaper::history();
    let history = history
        .iter()
        .skip(1) // skip the current wallpaper
        .map(|(path, _)| path)
        .collect_vec();

    let pqiv = format!(
        "{} pqiv {}",
        pqiv_float_rule(),
        history
            .iter()
            .map(|p| format!("'{}'", p.display()))
            .collect_vec()
            .join(" ")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}

fn write_wallpaper_history(wallpaper: PathBuf) {
    // not a wallpaper from the wallpapers dir
    if wallpaper.parent() != Some(&wallpaper::dir()) {
        return;
    }

    let mut history: HashMap<_, _> = wallpaper::history().into_iter().collect();
    // insert or update timestamp
    history.insert(wallpaper, chrono::Local::now().into());

    // update the csv
    let history_csv = full_path("~/Pictures/wallpapers_history.csv");
    let writer = std::io::BufWriter::new(
        std::fs::File::create(history_csv).expect("could not create wallpapers_history.csv"),
    );
    let mut wtr = csv::WriterBuilder::new()
        .has_headers(false)
        .from_writer(writer);

    for (path, dt) in &history {
        let filename = path
            .file_name()
            .expect("could not get timestamp filename")
            .to_str()
            .expect("could not convert filename to str");

        let row = [
            filename,
            &dt.to_rfc3339_opts(chrono::SecondsFormat::Secs, true),
        ];

        wtr.write_record(row)
            .unwrap_or_else(|_| panic!("could not write {row:?}"));
    }
    wtr.flush().expect("could not flush wallpapers_history.csv");
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
        wallpaper::current().expect("no current wallpaper set")
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
            None => wallpaper::random_from_dir(wallpaper::dir()),
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

    if !args.skip_wallpaper {
        wallpaper::set(&wallpaper, &args.transition);

        if !args.reload && !args.skip_history {
            write_wallpaper_history(PathBuf::from(wallpaper));
        }
    }
}
