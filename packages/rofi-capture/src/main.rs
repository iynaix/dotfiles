use std::path::PathBuf;

use clap::{CommandFactory, Parser, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use rofi_capture::{Screencast, Screenshot};

/*
    TODO:
    notify for video: save video path to lock file and read from there
*/

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
    name = "rofi-capture",
    about = "Rofi menu for screenshots / screencasts"
)]
pub struct RofiCaptureArgs {
    #[arg(long, action, help = "do video recording instead of screenshots")]
    pub video: bool,

    /// display rofi menu
    #[arg(long, action, help = "display rofi menu")]
    pub rofi: bool,

    #[arg(name = "capture", long, value_enum, help = "type of area to capture")]
    pub capture: Option<CaptureArea>,

    /// write to specific filename, otherwise creates one based on current time
    pub filename: Option<PathBuf>,

    #[arg(long, value_enum, help = "type of shell completion to generate")]
    pub generate_completions: Option<ShellCompletion>,
}

fn main() {
    let args = RofiCaptureArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate_completions {
        let mut cmd = RofiCaptureArgs::command();

        match shell {
            ShellCompletion::Bash => generate(
                Shell::Bash,
                &mut cmd,
                "rofi-capture",
                &mut std::io::stdout(),
            ),
            ShellCompletion::Zsh => {
                generate(Shell::Zsh, &mut cmd, "rofi-capture", &mut std::io::stdout())
            }
            ShellCompletion::Fish => generate(
                Shell::Fish,
                &mut cmd,
                "rofi-capture",
                &mut std::io::stdout(),
            ),
        }
        return;
    }

    // stop any currently recording videos
    if args.video && Screencast::stop() {
        println!("Stopping previous recording...");
        return;
    }

    if args.rofi {
        if args.video {
            Screencast::rofi(&args.filename);
        } else {
            Screenshot::rofi(&args.filename);
        }

        return;
    }

    if args.video {
        if let Some(area) = args.capture {
            let output_path = Screencast::output_path(args.filename);

            match area {
                CaptureArea::Monitor => Screencast::monitor(output_path),
                CaptureArea::Selection => Screencast::selection(output_path),
                CaptureArea::All => {
                    unimplemented!("Capturing of all outputs has not been implemented for video")
                }
            }
        }
    } else if let Some(area) = args.capture {
        let output_path = Screenshot::output_path(args.filename);

        match area {
            CaptureArea::Monitor => Screenshot::monitor(output_path),
            CaptureArea::Selection => Screenshot::selection(output_path),
            CaptureArea::All => Screenshot::all(output_path),
        }
    }
}
