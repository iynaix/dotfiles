use std::process::{Command, Stdio};

use execute::Execute;

use crate::full_path;

pub struct Rofi {
    choices: Vec<String>,
    command: Command,
}

impl Rofi {
    pub fn new<S>(theme: &str, choices: &[S]) -> Self
    where
        S: AsRef<str>,
    {
        let mut cmd = Command::new("rofi");

        cmd.arg("-dmenu")
            .arg("-theme")
            .arg(full_path(format!("~/.cache/wallust/{theme}")))
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
        }
    }

    #[must_use]
    pub fn arg<S: AsRef<std::ffi::OsStr>>(mut self, arg: S) -> Self {
        self.command.arg(arg);
        self
    }

    pub fn run(mut self) -> String {
        let selected = self
            .command
            .stdout(Stdio::piped())
            // use | as separator
            .execute_input_output(self.choices.join("|").as_bytes())
            .expect("failed to run rofi")
            .stdout;

        std::str::from_utf8(&selected)
            .expect("failed to parse utf8 from rofi selection")
            .strip_suffix('\n')
            .unwrap_or_default()
            .to_string()
    }
}
