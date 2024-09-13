use clap::{Command, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use execute::Execute;
use hyprland::{data::Monitors, shared::HyprData};
use nixinfo::NixInfo;
use std::{collections::HashMap, path::PathBuf, process::Stdio};

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

    let wrapped: Vec<_> = sys
        .processes_by_exact_name(wrapped_name.as_ref())
        .filter(|p| p.parent().map_or(false, |parent| parent.as_u32() == 1))
        .collect();

    if !wrapped.is_empty() {
        for p in wrapped {
            p.kill_with(signal);
        }
        return;
    }

    // kill unwrapped
    sys.processes_by_exact_name(wrapped_name.as_ref())
        .filter(|p| p.parent().map_or(false, |parent| parent.as_u32() == 1))
        .for_each(|p| {
            p.kill_with(signal);
        });
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

pub type WorkspacesByMonitor = HashMap<String, Vec<i32>>;

/// assign workspaces to their rules if possible, otherwise add them to the other monitors
pub fn rearranged_workspaces() -> WorkspacesByMonitor {
    let nix_monitors = NixInfo::before().monitors;
    let active_workspaces: HashMap<String, i32> = Monitors::get()
        .expect("could not get monitors")
        .iter()
        .map(|mon| (mon.name.clone(), mon.active_workspace.id))
        .collect();

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

                        if mon_idx != other_mon_idx && active_workspaces.contains_key(other_name) {
                            acc.entry(other_name.to_string())
                                .or_default()
                                .extend(&mon.workspaces);
                        }
                    }
                }
            }
            acc
        })
}
