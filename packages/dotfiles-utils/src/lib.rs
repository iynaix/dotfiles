use serde::de::DeserializeOwned;
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Command;

/// shared structs / types

type Coord = (i32, i32);

#[derive(Clone, Default, Deserialize, Debug)]
pub struct WorkspaceId {
    pub id: i32,
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

pub fn cmd(cmd_args: &[&str]) {
    match cmd_args {
        [] => panic!("empty command"),
        [head, tail @ ..] => {
            Command::new(head)
                .args(tail)
                .status()
                .unwrap_or_else(|_| panic!("failed to execute {}", head));
        }
    }
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

/// hyprctl monitors
#[derive(Clone, Default, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Monitor {
    pub id: i32,
    pub name: String,
    pub x: i32,
    pub y: i32,
    pub width: f32,
    pub height: f32,
    pub active_workspace: WorkspaceId,
    pub focused: bool,
    pub transform: i8,
}

impl Monitor {
    pub fn is_vertical(&self) -> bool {
        matches!(self.transform, 1 | 3 | 5 | 7)
    }

    pub fn is_ultrawide(&self) -> bool {
        self.width >= 3440.0
    }

    pub fn orientation(&self) -> &str {
        if self.is_vertical() {
            "orientationtop"
        } else {
            "orientationleft"
        }
    }

    pub fn stacks(&self) -> i32 {
        if self.is_ultrawide() || self.is_vertical() {
            3
        } else {
            2
        }
    }

    pub fn monitors() -> Vec<Monitor> {
        hypr_json("monitors")
    }

    pub fn focused() -> Monitor {
        Monitor::monitors()
            .into_iter()
            .find(|mon| mon.focused)
            .expect("no focused monitor found")
    }

    pub fn active_workspaces() -> HashMap<String, i32> {
        let mut active_monitors = HashMap::new();

        Monitor::monitors().into_iter().for_each(|mon| {
            active_monitors.insert(mon.name, mon.active_workspace.id);
        });

        active_monitors
    }

    pub fn rearranged_workspaces() -> HashMap<String, Vec<i32>> {
        let nix_monitors = NixInfo::from_config().monitors;
        let active_workspaces = Monitor::active_workspaces();

        let mut workspaces: HashMap<String, Vec<i32>> = HashMap::new();
        for (mon_idx, mon) in nix_monitors.iter().enumerate() {
            let name = &mon.name;

            match active_workspaces.get(name) {
                // active, use current workspaces
                Some(_) => workspaces
                    .entry(name.to_string())
                    .or_insert_with(Vec::new)
                    .extend(&mon.workspaces),
                // not active, add to the other monitors
                None => {
                    for (other_mon_idx, other_mon) in nix_monitors.iter().enumerate() {
                        let other_name = &other_mon.name;

                        if mon_idx != other_mon_idx && active_workspaces.contains_key(other_name) {
                            workspaces
                                .entry(other_name.to_string())
                                .or_insert_with(Vec::new)
                                .extend(&mon.workspaces)
                        }
                    }
                }
            }
        }

        workspaces
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

pub fn load_json_file<T>(path: &PathBuf) -> Result<T, Box<dyn std::error::Error>>
where
    T: serde::de::DeserializeOwned,
{
    let contents = std::fs::read_to_string(path)?;
    let res = serde_json::from_str(&contents)?;
    Ok(res)
}

pub fn write_json_file<T>(path: &PathBuf, data: T) -> Result<(), Box<dyn std::error::Error>>
where
    T: serde::Serialize,
{
    let file = std::fs::File::create(path)?;
    serde_json::to_writer(file, &data)?;
    Ok(())
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct Neofetch {
    pub logo: String,
    pub conf: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct Special {
    pub background: String,
    pub foreground: String,
    pub cursor: String,
}

#[derive(Clone, Default, Deserialize, Debug)]
pub struct NixMonitorInfo {
    pub name: String,
    pub workspaces: Vec<i32>,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct NixInfo {
    pub wallpaper: String,
    pub neofetch: Neofetch,
    pub special: Special,
    pub persistent_workspaces: bool,
    pub monitors: Vec<NixMonitorInfo>,
    /// color0 - color15
    pub colors: HashMap<String, String>,
}

impl NixInfo {
    /// get nix info from ~/.config before wallust has processed it
    pub fn from_config() -> NixInfo {
        let mut path = dirs::config_dir().unwrap_or_default();
        path.push("wallust/nix.json");

        load_json_file(&path).expect("could not load ~/.config/wallust/nix.json")
    }

    /// get nix info from ~/.cache after wallust has processed it
    pub fn from_cache() -> NixInfo {
        let mut path = dirs::cache_dir().unwrap_or_default();
        path.push("wallust/nix.json");

        load_json_file(&path).expect("could not load ~/.cache/wallust/nix.json")
    }

    /// get a vec of colors without # prefix
    pub fn hyprland_colors(&self) -> Vec<String> {
        (1..16)
            .map(|n| {
                let k = format!("color{}", n);
                format!("rgb({})", self.colors.get(&k).unwrap().replace('#', ""))
            })
            .collect()
    }
}
