use crate::monitor::Monitor;
use serde::{de::DeserializeOwned, Deserialize};
use std::path::PathBuf;
use std::process::Command;

pub mod cli;
pub mod monitor;
pub mod nixinfo;
pub mod wallpaper;
pub mod wallust;

/// shared structs / types

type Coord = (i32, i32);

#[derive(Clone, Default, Deserialize, Debug)]
pub struct WorkspaceId {
    pub id: i32,
}

pub fn full_path<P>(p: P) -> PathBuf
where
    P: AsRef<std::path::Path>,
{
    let p = p.as_ref().to_str().unwrap();

    match p.strip_prefix("~/") {
        Some(p) => dirs::home_dir().unwrap().join(p),
        None => PathBuf::from(p),
    }
}

/// reads json from a hyprctl -j command
pub fn hypr_json<T>(cmd: &str) -> T
where
    T: DeserializeOwned,
{
    let output = Command::new("hyprctl")
        .args(["-j", cmd])
        .output()
        .expect("failed to execute process");

    serde_json::from_slice(&output.stdout).expect("failed to parse json")
}

/// returns a command to be executed, and the command as a string
fn create_cmd<I, S>(cmd_args: I) -> (Command, String)
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    let mut args = cmd_args.into_iter();
    let first = args.next().expect("empty command");
    let first = first.as_ref();

    let mut cmd_str = vec![first.to_string()];
    let mut cmd = Command::new(first);

    for arg in args {
        let arg = arg.as_ref();
        cmd_str.push(arg.to_string());
        cmd.arg(arg);
    }

    (
        cmd,
        format!("failed to execute {first} {}", cmd_str.join(" ")),
    )
}

pub fn cmd<I, S>(cmd_args: I)
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    let (mut cmd, cmd_str) = create_cmd(cmd_args);
    cmd.status().unwrap_or_else(|_| panic!("{cmd_str}"));
}

pub enum CmdOutput {
    Stdout,
    Stderr,
}

pub fn cmd_output<I, S>(cmd_args: I, from: CmdOutput) -> Vec<String>
where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
{
    let (mut cmd, cmd_str) = create_cmd(cmd_args);
    let output = cmd.output().unwrap_or_else(|_| panic!("{cmd_str}"));

    std::str::from_utf8(match from {
        CmdOutput::Stdout => &output.stdout,
        CmdOutput::Stderr => &output.stderr,
    })
    .unwrap()
    .lines()
    .map(String::from)
    .collect()
}

/// hyprctl dispatch
pub fn hypr(hypr_args: &[&str]) {
    Command::new("hyprctl")
        .arg("dispatch")
        .args(hypr_args)
        .status()
        .expect("failed to execute process");
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
    pub fn new() -> ActiveWindow {
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
    pub fn clients() -> Vec<Client> {
        hypr_json("clients")
    }

    pub fn filter_class(class: String) -> Vec<Client> {
        Client::clients()
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
    pub fn workspaces() -> Vec<Workspace> {
        hypr_json("workspaces")
    }

    pub fn monitor(&self) -> Monitor {
        Monitor::monitors()
            .into_iter()
            .find(|m| m.name == self.monitor)
            .expect("monitor not found")
    }

    pub fn by_name(name: String) -> Workspace {
        Workspace::workspaces()
            .into_iter()
            .find(|w| w.name == name)
            .expect("workspace not found")
    }

    pub fn is_empty(&self) -> bool {
        self.windows == 0
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
            .unwrap_or_else(|_| panic!("failed to load {:?}", path));
        serde_json::from_str(&contents)
            .unwrap_or_else(|_| panic!("failed to parse json for {:?}", path))
    }

    pub fn write<T, P>(path: P, data: T)
    where
        T: serde::Serialize,
        P: AsRef<std::path::Path>,
    {
        let path = path.as_ref();
        let file = std::fs::File::create(full_path(path))
            .unwrap_or_else(|_| panic!("failed to load {:?}", path));
        serde_json::to_writer(file, &data)
            .unwrap_or_else(|_| panic!("failed to write json to {:?}", path));
    }
}
