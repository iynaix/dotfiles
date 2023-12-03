use serde::de::DeserializeOwned;
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Command;

pub mod cli;

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

/// hyprctl monitors
#[derive(Clone, Default, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Monitor {
    pub id: i32,
    pub name: String,
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub active_workspace: WorkspaceId,
    pub focused: bool,
    pub transform: i8,
}

impl Monitor {
    pub fn is_vertical(&self) -> bool {
        matches!(self.transform, 1 | 3 | 5 | 7)
    }

    pub fn is_ultrawide(&self) -> bool {
        self.width >= 3440
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
        hypr_json::<Vec<Monitor>>("monitors")
            .iter()
            .map(|mon| {
                if mon.is_vertical() {
                    Monitor {
                        width: mon.height,
                        height: mon.width,
                        ..mon.clone()
                    }
                } else {
                    mon.clone()
                }
            })
            .collect()
    }

    pub fn focused() -> Monitor {
        Monitor::monitors()
            .into_iter()
            .find(|mon| mon.focused)
            .expect("no focused monitor found")
    }

    pub fn active_workspaces() -> HashMap<String, i32> {
        Monitor::monitors()
            .into_iter()
            .map(|mon| (mon.name, mon.active_workspace.id))
            .collect()
    }

    pub fn rearranged_workspaces() -> HashMap<String, Vec<i32>> {
        let nix_monitors = NixInfo::before().monitors;
        let active_workspaces = Monitor::active_workspaces();

        nix_monitors
            .iter()
            .enumerate()
            .fold(HashMap::new(), |mut acc, (mon_idx, mon)| {
                let name = &mon.name;
                match active_workspaces.get(name) {
                    // active, use current workspaces
                    Some(_) => {
                        acc.entry(name.to_string())
                            .or_default()
                            .extend(&mon.workspaces);
                    }
                    // not active, add to the other monitors
                    None => {
                        for (other_mon_idx, other_mon) in nix_monitors.iter().enumerate() {
                            let other_name = &other_mon.name;

                            if mon_idx != other_mon_idx
                                && active_workspaces.contains_key(other_name)
                            {
                                acc.entry(other_name.to_string())
                                    .or_default()
                                    .extend(&mon.workspaces)
                            }
                        }
                    }
                }
                acc
            })
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
    pub fallback: String,
    pub neofetch: Neofetch,
    pub special: Special,
    pub persistent_workspaces: bool,
    pub monitors: Vec<NixMonitorInfo>,
    /// color0 - color15
    pub colors: HashMap<String, String>,
}

impl NixInfo {
    /// get nix info from ~/.config before wallust has processed it
    pub fn before() -> NixInfo {
        json::load("~/.config/wallust/nix.json")
    }

    /// get nix info from ~/.cache after wallust has processed it
    pub fn after() -> NixInfo {
        json::load("~/.cache/wallust/nix.json")
    }

    /// get a vec of colors without # prefix
    pub fn hyprland_colors(&self) -> Vec<String> {
        (1..16)
            .map(|n| {
                let k = format!("color{n}");
                format!("rgb({})", self.colors.get(&k).unwrap().replace('#', ""))
            })
            .collect()
    }
}

pub mod wallpaper {
    use rand::seq::SliceRandom;

    use crate::{cmd, cmd_output, full_path, json, CmdOutput, NixInfo};
    use std::{collections::HashMap, fs, path::PathBuf};

    pub fn dir() -> PathBuf {
        full_path("~/Pictures/Wallpapers")
    }

    pub fn current() -> Option<String> {
        let curr = NixInfo::after().wallpaper;

        let wallpaper = {
            if curr != "./foo/bar.text" {
                Some(curr)
            } else {
                fs::read_to_string(full_path("~/.cache/current_wallpaper")).ok()
            }
        };

        Some(
            wallpaper
                .expect("no wallpaper found")
                .replace("/persist", ""),
        )
    }

    /// returns all files in the wallpaper directory, exlcluding the current wallpaper
    pub fn all() -> Vec<String> {
        let curr = self::current().unwrap_or_default();

        self::dir()
            .read_dir()
            .unwrap()
            .flatten()
            .filter_map(|entry| {
                let path = entry.path();
                if path.is_file() {
                    if let Some(ext) = path.extension() {
                        match ext.to_str() {
                            Some("jpg") | Some("jpeg") | Some("png")
                                if curr != *path.to_str()? =>
                            {
                                return Some(path.to_str()?.to_string())
                            }
                            _ => return None,
                        }
                    }
                }

                None
            })
            .collect()
    }

    pub fn random() -> String {
        if self::dir().exists() {
            self::all()
                .choose(&mut rand::thread_rng())
                // use fallback image if not available
                .unwrap_or(&NixInfo::before().fallback)
                .to_string()
        } else {
            NixInfo::before().fallback
        }
    }

    /// creates a directory with randomly ordered wallpapers for imv to display
    pub fn randomize_wallpapers() -> String {
        let output_dir = full_path("~/.cache/wallpapers_random");
        let output_dir = output_dir.to_str().unwrap();

        // delete existing dir and recreate it
        fs::remove_dir_all(output_dir).unwrap_or(());
        fs::create_dir_all(output_dir).expect("could not create random wallpaper dir");

        // shuffle all wallpapers
        let mut rng = rand::thread_rng();
        let mut shuffled = self::all();
        shuffled.shuffle(&mut rng);

        let prefix_len = shuffled.len().to_string().len();
        for (idx, path) in shuffled.iter().enumerate() {
            let (_, img) = path.rsplit_once('/').unwrap();
            let new_path = format!("{output_dir}/{:0>1$}-{img}", idx, prefix_len);
            // create symlinks
            std::os::unix::fs::symlink(path, new_path).expect("failed to create symlink");
        }

        output_dir.to_string()
    }

    fn refresh_zathura() {
        if let Some(zathura_pid_raw) = cmd_output(
            [
                "dbus-send",
                "--print-reply",
                "--dest=org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus.ListNames",
            ],
            CmdOutput::Stdout,
        )
        .iter()
        .find(|line| line.contains("org.pwmt.zathura"))
        {
            let zathura_pid = zathura_pid_raw.split('"').max_by_key(|s| s.len()).unwrap();

            // send message to zathura via dbus
            cmd([
                "dbus-send",
                "--type=method_call",
                &format!("--dest={zathura_pid}"),
                "/org/pwmt/zathura",
                "org.pwmt.zathura.ExecuteCommand",
                "string:source",
            ]);
        }
    }

    /// applies the wallust colors to various applications
    pub fn wallust_apply_colors() {
        let c = if full_path("~/.cache/wallust/nix.json").exists() {
            NixInfo::after().hyprland_colors()
        } else {
            #[derive(serde::Deserialize)]
            struct Colorscheme {
                colors: HashMap<String, String>,
            }

            let cs_path = full_path("~/.config/wallust/catppuccin-mocha.json");
            let cs: Colorscheme = json::load(cs_path);

            (1..16)
                .map(|n| {
                    let k = format!("color{n}");
                    format!("rgb({})", cs.colors.get(&k).unwrap().replace('#', ""))
                })
                .collect()
        };

        if cfg!(feature = "hyprland") {
            // update borders
            cmd([
                "hyprctl",
                "keyword",
                "general:col.active_border",
                &format!("{} {} 45deg", c[4], c[0]),
            ]);
            cmd(["hyprctl", "keyword", "general:col.inactive_border", &c[0]]);

            // pink border for monocle windows
            cmd([
                "hyprctl",
                "keyword",
                "windowrulev2",
                "bordercolor",
                &format!("{},fullscreen:1", &c[5]),
            ]);
            // teal border for floating windows
            cmd([
                "hyprctl",
                "keyword",
                "windowrulev2",
                "bordercolor",
                &format!("{},floating:1", &c[6]),
            ]);
            // yellow border for sticky (must be floating) windows
            cmd([
                "hyprctl",
                "keyword",
                "windowrulev2",
                "bordercolor",
                &format!("{},pinned:1", &c[3]),
            ]);
        }

        // refresh zathura
        refresh_zathura();

        // refresh cava
        cmd(["killall", "-SIGUSR2", "cava"]);

        // refresh waifufetch
        cmd(["killall", "-SIGUSR2", "waifufetch"]);

        if cfg!(feature = "hyprland") {
            // sleep to prevent waybar race condition
            std::thread::sleep(std::time::Duration::from_secs(1));

            // refresh waybar
            cmd(["killall", "-SIGUSR2", ".waybar-wrapped"]);
        }

        // reload gtk theme
        // reload_gtk()
    }
}
