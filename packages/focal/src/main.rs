use std::path::PathBuf;

use clap::{ArgGroup, CommandFactory, Parser, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use focal::{create_parent_dirs, iso8601_filename, Screencast, Screenshot};

#[derive(Subcommand, ValueEnum, Debug, Clone)]
pub enum CaptureArea {
    Monitor,
    Selection,
    All,
}

#[derive(Subcommand, ValueEnum, Debug, Clone)]
pub enum ShellCompletion {
    Bash,
    Zsh,
    Fish,
}

#[derive(Parser, Debug)]
#[command(
    name = "focal",
    about = "Focal captures screenshots / videos using rofi, with clipboard support on hyprland"
)]
#[command(group(
    ArgGroup::new("video_options")
        .requires("video")
        .args(["audio"]),
))]
#[command(group(
    ArgGroup::new("image_options")
        .conflicts_with("video")
        .args(["edit", "ocr"]),
))]
pub struct FocalArgs {
    #[arg(long, action, help = "display rofi menu")]
    pub rofi: bool,

    #[arg(long, action, help = "use rofi theme")]
    pub theme: Option<PathBuf>,

    #[arg(long, value_enum, help = "type of area to capture")]
    pub area: Option<CaptureArea>,

    #[arg(long, help = "delay in seconds before capturing")]
    pub delay: Option<u64>, // sleep uses u64

    #[arg(long, action, help = "do not show notifications")]
    pub no_notify: bool,

    #[arg(long, action, help = "do not save the file permanently")]
    pub no_save: bool,

    #[arg(long, action, help = "do video recording instead of screenshots")]
    pub video: bool,

    #[arg(long, action, help = "capture video with audio")]
    pub audio: bool,

    #[arg(long, action, help = "edit screenshot with swappy")]
    pub edit: bool,

    #[arg(long, action, help = "run ocr on the selected text")]
    pub ocr: bool,

    #[arg(
        name = "FILE",
        long_help = "files are created in XDG_PICTURES_DIR/Screenshots or XDG_VIDEOS_DIR/Screencasts if not specified"
    )]
    pub filename: Option<PathBuf>,

    #[arg(
        long,
        value_enum,
        help = "type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

fn generate_completions(shell_completion: ShellCompletion) {
    let mut cmd = FocalArgs::command();

    match shell_completion {
        ShellCompletion::Bash => generate(Shell::Bash, &mut cmd, "focal", &mut std::io::stdout()),
        ShellCompletion::Zsh => generate(Shell::Zsh, &mut cmd, "focal", &mut std::io::stdout()),
        ShellCompletion::Fish => generate(Shell::Fish, &mut cmd, "focal", &mut std::io::stdout()),
    }
}

/// check if all required programs are installed
fn check_programs(args: &FocalArgs) {
    let mut progs = std::collections::HashSet::from(["notify-send", "wl-copy"]);

    if args.video {
        progs.insert("wf-recorder");
    } else {
        progs.insert("grim");
    }

    if args.rofi {
        progs.insert("rofi");
        progs.insert("slurp");
    }

    if let Some(CaptureArea::Selection) = args.area {
        progs.insert("slurp");
    }

    if args.edit {
        progs.insert("swappy");
    }

    if args.ocr {
        progs.insert("tesseract");
    }

    let not_found: Vec<_> = progs
        .into_iter()
        .filter(|prog| which::which(prog).is_err())
        .collect();

    if !not_found.is_empty() {
        eprintln!(
            "The following programs are required but not installed: {}",
            not_found.join(", ")
        );
        std::process::exit(1);
    }
}

fn main() {
    let args = FocalArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions(shell);
    }

    if !args.rofi && args.area.is_none() {
        FocalArgs::command()
            .error(
                clap::error::ErrorKind::MissingRequiredArgument,
                "Either --rofi or --area is required.",
            )
            .exit()
    }

    // check if all required programs are installed
    check_programs(&args);

    // stop any currently recording videos
    if args.video && Screencast::stop(!args.no_notify) {
        println!("Stopping previous recording...");
        return;
    }

    if args.video {
        let fname = format!("{}.mp4", iso8601_filename());

        let output = if args.no_save {
            PathBuf::from(format!("/tmp/{fname}"))
        } else {
            create_parent_dirs(args.filename.unwrap_or_else(|| {
                dirs::video_dir()
                    .expect("could not get $XDG_VIDEOS_DIR")
                    .join(format!("Screencasts/{}", fname))
            }))
        };

        let mut screencast = Screencast {
            output,
            delay: args.delay,
            audio: args.audio,
        };

        if args.rofi {
            screencast.rofi(&args.theme);
        } else if let Some(area) = args.area {
            match area {
                CaptureArea::Monitor => screencast.monitor(),
                CaptureArea::Selection => screencast.selection(),
                CaptureArea::All => {
                    unimplemented!("Capturing of all outputs has not been implemented for video")
                }
            }
        }
    } else {
        let fname = format!("{}.png", iso8601_filename());

        let output = if args.no_save {
            PathBuf::from(format!("/tmp/{fname}"))
        } else {
            create_parent_dirs(args.filename.unwrap_or_else(|| {
                dirs::picture_dir()
                    .expect("could not get $XDG_PICTURES_DIR")
                    .join(format!("Screenshots/{}", fname))
            }))
        };

        let mut screenshot = Screenshot {
            output,
            delay: args.delay,
            edit: args.edit,
            notify: !args.no_notify,
            ocr: args.ocr,
        };

        if args.rofi {
            screenshot.rofi(&args.theme);
        } else if let Some(area) = args.area {
            match area {
                CaptureArea::Monitor => screenshot.monitor(),
                CaptureArea::Selection => screenshot.selection(),
                CaptureArea::All => screenshot.all(),
            }
        }
    }
}
