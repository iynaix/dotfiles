use color_eyre::eyre::{OptionExt, Result};
use execute::Execute;
use std::process::{Command, Stdio};

pub struct NoctaliaDmenu {
    choices: Vec<String>,
    command: Command,
}

impl NoctaliaDmenu {
    pub fn new<S>(choices: &[S]) -> Self
    where
        S: AsRef<str>,
    {
        let mut cmd = Command::new("noctalia");
        cmd.arg("dmenu");

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

    pub fn run(self) -> Result<(String, i32)> {
        let mut output = self.command;

        let output = output
            .stdout(Stdio::piped())
            // use newline as separator
            .execute_input_output(self.choices.join("\n").as_bytes())?;

        let exit_code = output
            .status
            .code()
            .ok_or_eyre("noctalia dmenu has not exited")?;
        let selection = std::str::from_utf8(&output.stdout)?
            .strip_suffix('\n')
            .unwrap_or_default()
            .to_string();

        Ok((selection, exit_code))
    }
}
