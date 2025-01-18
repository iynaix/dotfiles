use clap::{CommandFactory, Parser};
use clap_complete::{generate, Shell};
use cli::{ShellCompletion, WallpaperArgs, WallpaperSubcommand};
use common::{full_path, wallpaper};
use std::{
    collections::HashMap,
    io::{Read, Write},
    path::PathBuf,
};

pub mod backup;
pub mod cli;
pub mod colorspace;
pub mod dedupe;
pub mod metadata;
pub mod pqiv;
pub mod search;
pub mod wallfacer;

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

fn get_random_wallpaper(image_or_dir: Option<PathBuf>) -> String {
    let random_wallpaper = match image_or_dir {
        // use stdin instead
        Some(p) if p == PathBuf::from("-") => {
            let mut buf = Vec::new();
            std::io::stdin()
                .read_to_end(&mut buf)
                .expect("unable to read stdin");

            // valid image, write stdin to a file
            if let Ok(format) = image::guess_format(&buf) {
                // need to write the extension or Image has problems guessing the format later
                let ext = format.extensions_str()[0];

                let output = format!("/tmp/__wall__{}.{ext}", fastrand::u32(10000..));
                std::fs::write(&output, &buf).expect("could not write stdin to file");
                output
            } else {
                String::from_utf8(buf)
                    .ok()
                    .and_then(|s| std::fs::canonicalize(s.trim()).ok())
                    .map_or_else(
                        || panic!("unable to parse stdin"),
                        |p| p.to_string_lossy().to_string(),
                    )
            }
        }
        Some(image_or_dir) => {
            if image_or_dir.is_dir() {
                wallpaper::random_from_dir(&image_or_dir)
            } else {
                std::fs::canonicalize(&image_or_dir)
                    .unwrap_or_else(|_| {
                        panic!("{} is not a valid image / command", &image_or_dir.display())
                    })
                    .to_str()
                    .unwrap_or_else(|| panic!("could not convert {image_or_dir:?} to str"))
                    .to_string()
            }
        }
        None => wallpaper::random_from_dir(wallpaper::dir()),
    };

    // write current wallpaper to $XDG_RUNTIME_DIR/current_wallpaper
    std::fs::write(
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("current_wallpaper"),
        &random_wallpaper,
    )
    .ok();

    random_wallpaper
}

fn main() {
    let args = WallpaperArgs::parse();

    let is_reload = args.reload || args.command == Some(WallpaperSubcommand::Reload);

    // handle subcommand
    if !is_reload {
        if let Some(command) = args.command {
            match command {
                WallpaperSubcommand::Generate(args) => {
                    let mut cmd = WallpaperArgs::command();
                    match &args.shell {
                        ShellCompletion::Bash => {
                            generate(Shell::Bash, &mut cmd, "wallpaper", &mut std::io::stdout());
                        }
                        ShellCompletion::Zsh => {
                            generate(Shell::Zsh, &mut cmd, "wallpaper", &mut std::io::stdout());
                        }
                        ShellCompletion::Fish => {
                            generate(Shell::Fish, &mut cmd, "wallpaper", &mut std::io::stdout());
                        }
                    }
                }
                WallpaperSubcommand::Current => println!(
                    "{}",
                    wallpaper::current().unwrap_or_else(|| {
                        eprintln!("Failed to get current wallpaper");
                        std::process::exit(1)
                    })
                ),
                WallpaperSubcommand::Rm => {
                    let fname = wallpaper::current().unwrap_or_else(|| {
                        eprintln!("Failed to get current wallpaper");
                        std::process::exit(1)
                    });

                    print!("Delete {fname}? (y/N): ");
                    std::io::stdout().flush().expect("could not flush stdout");

                    let mut input = String::new();
                    std::io::stdin()
                        .read_line(&mut input)
                        .expect("could not read stdin");

                    if input.trim().eq_ignore_ascii_case("y") {
                        std::fs::remove_file(&fname).unwrap_or_else(|_| {
                            eprintln!("Error deleting {fname}");
                            std::process::exit(1);
                        });
                    }
                }
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
                WallpaperSubcommand::Colorspace(args) => colorspace::toggle(args),
                WallpaperSubcommand::Metadata(args) => metadata::metadata(args),
                WallpaperSubcommand::Reload => {} // handled later
            }
            return;
        }
    }

    let wallpaper = if is_reload {
        wallpaper::current().expect("no current wallpaper set")
    } else {
        get_random_wallpaper(args.image_or_dir)
    };

    if !args.skip_wallpaper {
        wallpaper::set(&wallpaper, &args.transition);

        if !is_reload && !args.skip_history {
            write_wallpaper_history(PathBuf::from(wallpaper));
        }
    }
}
