use crate::cli::{AddArgs, EditArgs};
use color_eyre::eyre::Result;
use common::{full_path, wallpaper};
use std::{
    path::PathBuf,
    process::{Command, Stdio},
};

struct Wallfacer {
    command: Command,
}

impl Wallfacer {
    pub fn try_new() -> Result<Self> {
        let wallfacer_dir = full_path("~/projects/wallfacer");
        let wallfacer_dir = PathBuf::from("/persist").join(wallfacer_dir.strip_prefix("/")?);

        let mut cmd = Command::new("direnv");

        cmd
            // not setting current dir causes wallfacer to be unstyled
            .current_dir(&wallfacer_dir)
            .arg("exec")
            .arg(&wallfacer_dir)
            .args([
                "cargo",
                "run",
                "--release",
                "--bin",
                "wallfacer",
                "--manifest-path",
            ])
            .arg(wallfacer_dir.join("Cargo.toml"))
            .arg("--");

        Ok(Self { command: cmd })
    }

    pub fn arg<S: AsRef<std::ffi::OsStr>>(mut self, arg: S) -> Self {
        self.command.arg(arg);
        self
    }

    pub fn args<I, S>(mut self, args: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: AsRef<std::ffi::OsStr>,
    {
        self.command.args(args);
        self
    }

    pub fn run(&mut self) -> Result<std::process::Child> {
        Ok(self
            .command
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .spawn()?)
    }
}

pub fn edit(args: EditArgs) -> Result<()> {
    let image = args.file.unwrap_or(wallpaper::current()?.into());

    let wallfacer = Wallfacer::try_new()?;
    wallfacer.arg("gui").arg(&image).run()?.wait()?;

    // reload the wallpaper
    wallpaper::set(&image)?;

    Ok(())
}

pub fn add(args: AddArgs) -> Result<()> {
    let mut image_or_dir = args
        .image_or_dir
        .unwrap_or_else(|| full_path("~/Pictures/wallpapers_in"));

    let mut rest_args = args.rest.clone();
    if !args.rest.is_empty() {
        let last = args.rest.last().unwrap_or_else(|| {
            eprintln!("No arguments provided");
            std::process::exit(1);
        });
        if PathBuf::from(last).exists() {
            image_or_dir = last.into();
            rest_args.pop();
        }
    }

    Wallfacer::try_new()?
        .arg("add")
        .arg("--format")
        .arg("webp")
        .args(rest_args)
        .arg(image_or_dir)
        .run()?
        .wait()?;

    Ok(())
}
