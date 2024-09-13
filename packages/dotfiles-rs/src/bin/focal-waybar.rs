//! updates the focal waybar module with the current recording status

use std::path::PathBuf;

use clap::{CommandFactory, Parser, ValueEnum};
use dotfiles::{generate_completions, ShellCompletion};
use serde::{Deserialize, Serialize};

#[derive(Default, Debug, Serialize)]
pub struct WaybarModule {
    pub text: String,
    pub class: String,
    pub tooltip: String,
}

#[derive(Serialize, Deserialize)]
struct LockFile {
    pid: u32,
    child: u32,
    video: PathBuf,
}

impl LockFile {
    fn path() -> PathBuf {
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("focal.lock")
    }

    fn read() -> std::io::Result<Self> {
        let content = std::fs::read_to_string(Self::path())?;
        serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))
    }
}

#[derive(ValueEnum, Clone, Debug)]
pub enum Operation {
    Start,
    Stop,
}

#[derive(Parser, Debug)]
#[command(
    name = "focal-waybar",
    about = "Updates the display of the focal waybar module"
)]
pub struct FocalWaybarArgs {
    #[arg(value_enum)]
    pub operation: Operation,

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
    let args = FocalWaybarArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("hypr-monitors", &mut FocalWaybarArgs::command(), &shell);
        std::process::exit(0);
    }

    match args.operation {
        Operation::Start => {
            let lock = LockFile::read().expect("could not read lock file");
            let waybar = WaybarModule {
                text: format!("<span color=\"{}\">󰑋</span>", "#ff0000"),
                tooltip: format!("Recording {}", lock.video.display()),
                class: "custom/focal".to_string(),
            };

            println!(
                "{}",
                serde_json::to_string(&waybar).expect("unable to serialize waybar module")
            );
        }
        Operation::Stop => {
            //
            println!("Hide widget");
        }
    }
}
