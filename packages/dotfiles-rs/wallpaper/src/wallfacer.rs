use crate::cli::{AddArgs, EditArgs};
use common::{full_path, wallpaper};
use execute::Execute;
use std::process::{Command, Stdio};

struct Wallfacer {
    command: Command,
}

impl Wallfacer {
    pub fn new() -> Self {
        let wallfacer_dir = full_path("~/projects/wallfacer");

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

        Self { command: cmd }
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

    pub fn run(&mut self) {
        self.command
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .execute()
            .expect("failed to run wallfacer");
    }
}

pub fn edit(args: EditArgs) {
    let image = args.file.unwrap_or_else(|| {
        wallpaper::current()
            .expect("failed to get current wallpaper")
            .into()
    });

    let wallfacer = Wallfacer::new();
    wallfacer.arg(&image).run();

    // reload the wallpaper
    wallpaper::set(&image, &None);
}

pub fn add(args: AddArgs) {
    let images_or_dirs = args
        .images_or_dirs
        .unwrap_or_else(|| vec![full_path("~/Pictures/wallpapers_in")]);

    Wallfacer::new()
        .arg("add")
        .arg("--format")
        .arg("webp")
        .args(images_or_dirs)
        .run();
}
