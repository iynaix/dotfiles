use std::path::PathBuf;

use clap::{CommandFactory, Parser, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use rofi_capture::{Screencast, Screenshot};

/*
    TODO:
    tesseract?
    --notify option?
    arg groups for formatting?
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
    #[arg(long, action, help = "display rofi menu")]
    pub rofi: bool,

    #[arg(name = "capture", long, value_enum, help = "type of area to capture")]
    pub capture: Option<CaptureArea>,

    #[arg(long, help = "delay in seconds before capturing")]
    pub delay: Option<u64>, // sleep uses u64

    #[arg(long, action, help = "use rofi theme")]
    pub theme: Option<PathBuf>,

    #[arg(long, action, help = "do video recording instead of screenshots")]
    pub video: bool,

    #[arg(long, action, help = "capture video with audio")]
    pub audio: Option<bool>,

    #[arg(long, action, help = "edit screenshot with swappy")]
    pub edit: Option<bool>,

    /// write to specific filename, otherwise creates one based on current time
    pub filename: Option<PathBuf>,

    #[arg(long, value_enum, help = "type of shell completion to generate")]
    pub generate_completions: Option<ShellCompletion>,
}

fn generate_completions(shell_completion: ShellCompletion) {
    let mut cmd = RofiCaptureArgs::command();

    match shell_completion {
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
}

fn main() {
    let args = RofiCaptureArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate_completions {
        return generate_completions(shell);
    }

    // stop any currently recording videos
    if args.video && Screencast::stop() {
        println!("Stopping previous recording...");
        return;
    }

    if args.video {
        let mut screencast = Screencast::new(args.filename.clone(), args.delay, args.audio);
        if args.rofi {
            screencast.rofi(&args.theme);
        } else if let Some(area) = args.capture {
            match area {
                CaptureArea::Monitor => screencast.monitor(),
                CaptureArea::Selection => screencast.selection(),
                CaptureArea::All => {
                    unimplemented!("Capturing of all outputs has not been implemented for video")
                }
            }
        }
    } else {
        let screenshot = Screenshot::new(args.filename.clone(), args.delay, args.edit);

        if args.rofi {
            screenshot.rofi(&args.theme);
        } else if let Some(area) = args.capture {
            match area {
                CaptureArea::Monitor => screenshot.monitor(),
                CaptureArea::Selection => screenshot.selection(),
                CaptureArea::All => screenshot.all(),
            }
        }
    }
}
