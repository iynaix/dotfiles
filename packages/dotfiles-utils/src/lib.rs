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
    P: AsRef<std::path::Path>,
{
    let p = p.as_ref().to_str().expect("invalid path");

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
        .expect("failed to execute process");

    serde_json::from_slice(&output.stdout).expect("failed to parse json")
}

fn command_output_to_lines(output: &[u8]) -> Vec<String> {
    String::from_utf8(output.to_vec())
        .expect("invalid utf8 from command")
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
    cmd.execute().expect("failed to execute hyprctl");
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
            .expect("monitor not found")
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
            .expect("monitor not found")
    }

    pub fn by_name(name: &str) -> Option<Self> {
        Self::workspaces().into_iter().find(|w| w.name == name)
    }
}

pub mod json {
    use super::full_path;

    pub fn load<T, P>(path: P) -> T
    where
        T: serde::de::DeserializeOwned,
        P: AsRef<std::path::Path>,
    {
        let path = path.as_ref();
        let contents = std::fs::read_to_string(full_path(path))
            .unwrap_or_else(|_| panic!("failed to load {path:?}"));
        serde_json::from_str(&contents)
            .unwrap_or_else(|_| panic!("failed to parse json for {path:?}"))
    }

    pub fn write<T, P>(path: P, data: T)
    where
        T: serde::Serialize,
        P: AsRef<std::path::Path>,
    {
        let path = path.as_ref();
        let file = std::fs::File::create(full_path(path))
            .unwrap_or_else(|_| panic!("failed to create {path:?}"));
        serde_json::to_writer(file, &data)
            .unwrap_or_else(|_| panic!("failed to write json to {path:?}"));
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
