use clap::{ArgGroup, Args, CommandFactory, Parser, Subcommand};
use common::{full_path, generate_completions, wallpaper, ShellCompletion};
use std::collections::HashMap;
use std::path::PathBuf;

pub mod backup;
pub mod dedupe;
pub mod pqiv;
pub mod search;
pub mod toggle;
pub mod wallfacer;

#[derive(Args, Debug, PartialEq, Eq)]
pub struct GenerateArgs {
    #[arg(value_enum, help = "Type of shell completion to generate")]
    pub shell: ShellCompletion,
}

#[derive(Subcommand, Debug, PartialEq)]
enum WallpaperSubcommand {
    #[command(name = "generate", about = "Generate shell completions", hide = true)]
    Generate(GenerateArgs),

    #[command(name = "current", about = "Prints the path of the current wallpaper")]
    Current,

    #[command(name = "reload", about = "Reloads the current wallpaper")]
    Reload,

    #[command(name = "history", about = "Show wallpaper history selector with pqiv")]
    History,

    #[command(
        name = "rofi",
        visible_alias = "pqiv",
        about = "Show wallpaper selector with pqiv"
    )]
    Rofi,

    #[cfg(feature = "dedupe")]
    #[command(
        name = "dedupe",
        visible_aliases = ["czkawka", "unique", "uniq"],
        about = "Runs czkawka to show duplicate wallpapers"
    )]
    Dedupe,

    #[cfg(feature = "wallfacer")]
    #[command(
        name = "edit",
        visible_alias = "recrop",
        about = "Edit and reload the current wallpaper with wallfacer"
    )]
    Edit(wallfacer::EditArgs),

    #[cfg(feature = "wallfacer")]
    #[command(
        name = "add",
        about = "Processes wallpapers with upscaling and vertical crop"
    )]
    Add(wallfacer::AddArgs),

    #[cfg(feature = "rclip")]
    #[command(
        name = "search",
        visible_aliases = ["rg", "grep", "find"],
        about = "Search for wallpapers using rclip"
    )]
    Search(search::SearchArgs),

    #[command(name = "backup", about = "Backup wallpapers to secondary location")]
    Backup(backup::BackupArgs),

    #[command(
        name = "remote",
        visible_alias = "sync",
        about = "Sync wallpapers to another machine"
    )]
    Remote(backup::RemoteArgs),

    #[command(
        name = "toggle",
        visible_alias = "colorspace",
        about = "Toggles and saves the colorspace for wallust"
    )]
    Toggle(toggle::ToggleArgs),
}

#[allow(clippy::struct_excessive_bools)]
#[derive(Parser, Debug)]
#[command(
    name = "wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
#[command(group(
    ArgGroup::new("exclusive_group")
        .args(&["reload", "image_or_dir"])
        .multiple(false)
))]
struct WallpaperArgs {
    #[command(subcommand)]
    pub command: Option<WallpaperSubcommand>,

    #[arg(long, action, help = "Reload current wallpaper")]
    pub reload: bool,

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

fn write_wallpaper_history(wallpaper: PathBuf) {
    // not a wallpaper from the wallpapers dir
    if wallpaper.parent() != Some(&wallpaper::dir()) {
        return;
    }

    let mut history: HashMap<_, _> = wallpaper::history().into_iter().collect();
    // insert or update timestamp
    history.insert(wallpaper, chrono::Local::now().into());

    // update the history csv
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
    let args = WallpaperArgs::parse();

    let is_reload = args.reload || args.command == Some(WallpaperSubcommand::Reload);

    // handle subcommand
    if let Some(command) = args.command {
        match command {
            WallpaperSubcommand::Generate(args) => {
                generate_completions("focal", &mut WallpaperArgs::command(), &args.shell);
            }
            WallpaperSubcommand::Current => println!(
                "{}",
                wallpaper::current().unwrap_or_else(|| {
                    eprintln!("Failed to get current wallpaper");
                    std::process::exit(1)
                })
            ),
            WallpaperSubcommand::Reload => {} // handled later
            WallpaperSubcommand::History => pqiv::show_history(),
            WallpaperSubcommand::Rofi => pqiv::show_pqiv(),
            #[cfg(feature = "dedupe")]
            WallpaperSubcommand::Dedupe => dedupe::dedupe(),
            #[cfg(feature = "wallfacer")]
            WallpaperSubcommand::Edit(args) => wallfacer::edit(args),
            #[cfg(feature = "wallfacer")]
            WallpaperSubcommand::Add(args) => wallfacer::add(args),
            #[cfg(feature = "rclip")]
            WallpaperSubcommand::Search(args) => search::search(args),
            WallpaperSubcommand::Backup(args) => backup::backup(args),
            WallpaperSubcommand::Remote(args) => backup::remote(args),
            WallpaperSubcommand::Toggle(args) => toggle::toggle(args),
        }
        return;
    }

    let wallpaper = if is_reload {
        wallpaper::current().expect("no current wallpaper set")
    } else {
        let random_wallpaper = match args.image_or_dir {
            Some(image_or_dir) => {
                if image_or_dir.is_dir() {
                    wallpaper::random_from_dir(&image_or_dir)
                } else {
                    std::fs::canonicalize(&image_or_dir)
                        .unwrap_or_else(|_| {
                            panic!(
                                "{} is not a valid image / subcommand",
                                &image_or_dir.display()
                            )
                        })
                        .to_str()
                        .unwrap_or_else(|| panic!("could not convert {image_or_dir:?} to str"))
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

        if !is_reload && !args.skip_history {
            write_wallpaper_history(PathBuf::from(wallpaper));
        }
    }
}
