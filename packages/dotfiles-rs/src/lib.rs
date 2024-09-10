use clap::{Command, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use execute::Execute;
use hyprland::shared::HyprData;
use serde::{de::DeserializeOwned, Deserialize};
use std::{path::PathBuf, process::Stdio};

pub mod monitor;
pub mod nixinfo;
pub mod rofi;
pub mod wallpaper;
pub mod wallust;

// utilities for generating shell completions
#[derive(Subcommand, ValueEnum, Debug, Clone)]
pub enum ShellCompletion {
    Bash,
    Zsh,
    Fish,
}

pub fn generate_completions(progname: &str, cmd: &mut Command, shell_completion: &ShellCompletion) {
    match shell_completion {
        ShellCompletion::Bash => generate(Shell::Bash, cmd, progname, &mut std::io::stdout()),
        ShellCompletion::Zsh => generate(Shell::Zsh, cmd, progname, &mut std::io::stdout()),
        ShellCompletion::Fish => generate(Shell::Fish, cmd, progname, &mut std::io::stdout()),
    }
}

// shared structs / types
type Coord = (i32, i32);

#[derive(Clone, Default, Deserialize, Debug)]
pub struct WorkspaceId {
    pub id: i32,
}

pub fn full_path<P>(p: P) -> PathBuf
where
    P: AsRef<std::path::Path> + std::fmt::Debug,
{
    let p = p
        .as_ref()
        .to_str()
        .unwrap_or_else(|| panic!("invalid path: {p:?}"));

    match p.strip_prefix("~/") {
        Some(p) => dirs::home_dir().expect("invalid home directory").join(p),
        None => PathBuf::from(p),
    }
}

/// reads json from a hyprctl -j command
pub fn hypr_json<T>(cmd: &str) -> T
where
    T: DeserializeOwned,
{
    let output = execute::command_args!("hyprctl", "-j", cmd)
        .stdout(Stdio::piped())
        .execute_output()
        .expect("failed to execute hyprctl");

    serde_json::from_slice(&output.stdout).expect("failed to parse json from hyprctl")
}

fn command_output_to_lines(output: &[u8]) -> Vec<String> {
    String::from_utf8(output.to_vec())
        .unwrap_or_else(|_| panic!("invalid utf8 from command: {output:?}"))
        .lines()
        .map(String::from)
        .collect()
}

pub trait CommandUtf8 {
    fn execute_stdout_lines(&mut self) -> Vec<String>;

    fn execute_stderr_lines(&mut self) -> Vec<String>;
}

impl CommandUtf8 for std::process::Command {
    fn execute_stdout_lines(&mut self) -> Vec<String> {
        self.stdout(Stdio::piped()).execute_output().map_or_else(
            |_| Vec::new(),
            |output| command_output_to_lines(&output.stdout),
        )
    }

    fn execute_stderr_lines(&mut self) -> Vec<String> {
        self.stderr(Stdio::piped()).execute_output().map_or_else(
            |_| Vec::new(),
            |output| command_output_to_lines(&output.stderr),
        )
    }
}

/// hyprctl clients
#[derive(Clone, Default, Deserialize, Debug)]
pub struct Client {
    pub class: String,
    pub address: String,
    pub floating: bool,
    pub workspace: WorkspaceId,
    pub at: Coord,
    pub size: Coord,
}

impl Client {
    pub fn clients() -> Vec<Self> {
        hypr_json("clients")
    }

    pub fn by_id(id: &str) -> Option<Self> {
        Self::clients()
            .into_iter()
            .find(|client| client.address.ends_with(id))
    }

    pub fn filter_workspace(wksp_id: i32) -> Vec<Self> {
        Self::clients()
            .into_iter()
            .filter(|client| client.workspace.id == wksp_id)
            .collect()
    }

    pub fn filter_class(class: &str) -> Vec<Self> {
        Self::clients()
            .into_iter()
            .filter(|client| client.class == class)
            .collect()
    }
}

pub fn filename<P>(path: P) -> String
where
    P: AsRef<std::path::Path> + std::fmt::Debug,
{
    path.as_ref()
        .file_name()
        .unwrap_or_else(|| panic!("could not get filename: {path:?}"))
        .to_str()
        .unwrap_or_else(|| panic!("could not convert filename to str: {path:?}"))
        .to_string()
}

pub mod json {
    use super::full_path;

    pub fn load<T, P>(path: P) -> std::io::Result<T>
    where
        T: serde::de::DeserializeOwned,
        P: AsRef<std::path::Path>,
    {
        let path = path.as_ref();
        let contents = std::fs::read_to_string(full_path(path))?;
        Ok(serde_json::from_str::<T>(&contents)?)
    }

    pub fn write<T, P>(path: P, data: T) -> std::io::Result<()>
    where
        T: serde::Serialize,
        P: AsRef<std::path::Path>,
    {
        let path = path.as_ref();
        let file = std::fs::File::create(full_path(path))?;
        serde_json::to_writer(file, &data)?;
        Ok(())
    }
}

pub fn kill_wrapped_process(unwrapped_name: &str, signal: sysinfo::Signal) {
    let mut sys = sysinfo::System::new();
    sys.refresh_processes(sysinfo::ProcessesToUpdate::All);

    let wrapped_name = format!(".{unwrapped_name}-wrapped");
    let mut wrapped_process = sys.processes_by_exact_name(wrapped_name.as_ref());

    if let Some(process) = wrapped_process.next() {
        process.kill_with(signal);
    } else if let Some(process) = sys.processes_by_exact_name(unwrapped_name.as_ref()).next() {
        process.kill_with(signal);
    }
}

pub fn iso8601_filename() -> String {
    chrono::Local::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)
}

/// swaps the dimenions if the monitor is vertical
pub fn vertical_dimensions(mon: &hyprland::data::Monitor) -> (i32, i32) {
    if mon.transform as u8 % 2 == 1 {
        (mon.height.into(), mon.width.into())
    } else {
        (mon.width.into(), mon.height.into())
    }
}

pub fn find_monitor_by_name(name: &str) -> Option<hyprland::data::Monitor> {
    hyprland::data::Monitors::get()
        .expect("could not get monitors")
        .iter()
        .find(|mon| mon.name == name)
        .cloned()
}
