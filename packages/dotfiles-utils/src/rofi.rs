use std::process::{Command, Stdio};

use execute::Execute;

use crate::full_path;

pub struct Rofi {
    theme: String,
    choices: Vec<String>,
}

impl Rofi {
    pub fn new<S>(theme: &str, choices: &[S]) -> Self
    where
        S: AsRef<str>,
    {
        Self {
            theme: theme.to_string(),
            choices: choices.iter().map(|s| s.as_ref().to_string()).collect(),
        }
    }

    pub fn command(&self) -> Command {
        let mut cmd = Command::new("rofi");

        cmd.arg("-dmenu")
            .arg("-theme")
            .arg(full_path(format!("~/.cache/wallust/{}", self.theme)))
            // use | as separator
            .arg("-sep")
            .arg("|")
            .arg("-disable-history")
            .arg("true")
            .arg("-cycle")
            .arg("true");

        cmd
    }

    pub fn run(&self, rofi_cmd: &mut Command) -> String {
        let selected = rofi_cmd
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
