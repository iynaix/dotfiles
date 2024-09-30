use std::{
    path::PathBuf,
    process::{Command, Stdio},
};

use execute::Execute;

use crate::full_path;

pub struct Rofi {
    choices: Vec<String>,
    command: Command,
    theme: PathBuf,
}

impl Rofi {
    pub fn new<S>(choices: &[S]) -> Self
    where
        S: AsRef<str>,
    {
        let mut cmd = Command::new("rofi");

        cmd.arg("-dmenu")
            // .arg("-theme")
            // .arg(full_path(format!("~/.cache/wallust/{theme}")))
            // use | as separator
            .arg("-sep")
            .arg("|")
            .arg("-disable-history")
            .arg("true")
            .arg("-cycle")
            .arg("true");

        Self {
            choices: choices.iter().map(|s| s.as_ref().to_string()).collect(),
            command: cmd,
            theme: full_path("~/.cache/wallust/rofi-menu-noinput.rasi"),
        }
    }

    #[must_use]
    pub fn arg<S: AsRef<std::ffi::OsStr>>(mut self, arg: S) -> Self {
        self.command.arg(arg);
        self
    }

    #[must_use]
    pub fn theme(mut self, theme: PathBuf) -> Self {
        self.theme = theme;
        self
    }

    pub fn run(self) -> (String, i32) {
        let mut output = self.command;

        if self.theme.exists() {
            output.arg("-theme").arg(self.theme);
        }

        let output = output
            .stdout(Stdio::piped())
            // use | as separator
            .execute_input_output(self.choices.join("|").as_bytes())
            .expect("failed to run rofi");

        let exit_code = output.status.code().expect("rofi has not exited");
        let selection = std::str::from_utf8(&output.stdout)
            .expect("failed to parse utf8 from rofi selection")
            .strip_suffix('\n')
            .unwrap_or_default()
            .to_string();

        (selection, exit_code)
    }
}
