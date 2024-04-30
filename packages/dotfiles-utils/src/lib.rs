use crate::monitor::Monitor;
use execute::Execute;
use serde::{de::DeserializeOwned, Deserialize};
use std::{path::PathBuf, process::Stdio};

pub mod cli;
pub mod monitor;
pub mod nixinfo;
pub mod wallpaper;
pub mod wallust;

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

/// hyprctl dispatch
pub fn hypr<I, S>(hypr_args: I)
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    let mut cmd = execute::command_args!("hyprctl", "dispatch");

    for arg in hypr_args {
        cmd.arg(arg.as_ref());
    }
    cmd.execute().expect("failed to execute hyprctl dispatch");
}

/// hyprctl activewindow
#[derive(Clone, Default, Deserialize, Debug)]
pub struct ActiveWindow {
    pub monitor: i32,
    pub floating: bool,
    pub at: Coord,
    pub class: String,
    pub address: String,
}

impl ActiveWindow {
    pub fn new() -> Self {
        hypr_json("activewindow")
    }

    pub fn get_monitor(&self) -> Monitor {
        Monitor::monitors()
            .into_iter()
            .find(|m| m.id == self.monitor)
            .unwrap_or_else(|| panic!("monitor {} not found", self.monitor))
    }
}

/// hyprctl clients
#[derive(Clone, Default, Deserialize, Debug)]
pub struct Client {
    pub class: String,
    pub address: String,
    pub workspace: WorkspaceId,
    pub at: Coord,
}

impl Client {
    pub fn clients() -> Vec<Self> {
        hypr_json("clients")
    }

    pub fn filter_class(class: &str) -> Vec<Self> {
        Self::clients()
            .into_iter()
            .filter(|client| client.class == class)
            .collect()
    }
}

/// hyprctl workspaces
#[derive(Clone, Default, Deserialize, Debug)]
pub struct Workspace {
    pub id: i32,
    pub name: String,
    pub windows: i32,
    pub monitor: String,
}

impl Workspace {
    pub fn workspaces() -> Vec<Self> {
        hypr_json("workspaces")
    }

    pub fn monitor(&self) -> Monitor {
        Monitor::monitors()
            .into_iter()
            .find(|m| m.name == self.monitor)
            .unwrap_or_else(|| panic!("monitor {} not found", self.monitor))
    }

    pub fn by_name(name: &str) -> Option<Self> {
        Self::workspaces().into_iter().find(|w| w.name == name)
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

pub fn execute_wrapped_process<F>(unwrapped_name: &str, process_fn: F)
where
    F: Fn(&str),
{
    let wrapped_name = &format!(".{unwrapped_name}-wrapped");
    let sys = sysinfo::System::new_all();

    if sys.processes_by_exact_name(wrapped_name).next().is_some() {
        process_fn(wrapped_name);
    } else {
        process_fn(unwrapped_name);
    }
}
