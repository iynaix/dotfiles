use execute::Execute;
use nixinfo::NixMonitorInfo;
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

pub mod colors;
pub mod nixinfo;
pub mod rofi;
pub mod swww;
pub mod wallpaper;
pub mod wallust;

pub fn full_path<P>(p: P) -> PathBuf
where
    P: AsRef<Path> + std::fmt::Debug,
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
    fn execute_stdout_lines(&mut self) -> Result<Vec<String>, std::io::Error>;

    fn execute_stderr_lines(&mut self) -> Result<Vec<String>, std::io::Error>;
}

impl CommandUtf8 for Command {
    fn execute_stdout_lines(&mut self) -> Result<Vec<String>, std::io::Error> {
        self.stdout(Stdio::piped())
            .execute_output()
            .map(|output| command_output_to_lines(&output.stdout))
    }

    fn execute_stderr_lines(&mut self) -> Result<Vec<String>, std::io::Error> {
        self.stderr(Stdio::piped())
            .execute_output()
            .map(|output| command_output_to_lines(&output.stderr))
    }
}

pub fn filename<P>(path: P) -> String
where
    P: AsRef<Path> + std::fmt::Debug,
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
    use std::path::Path;

    pub fn load<T, P>(path: P) -> Result<T, Box<dyn std::error::Error>>
    where
        T: serde::de::DeserializeOwned,
        P: AsRef<Path>,
    {
        let path = path.as_ref();
        let contents = std::fs::read_to_string(full_path(path))?;
        Ok(serde_json::from_str::<T>(&contents)?)
    }

    pub fn write<T, P>(path: P, data: T) -> std::io::Result<()>
    where
        T: serde::Serialize,
        P: AsRef<Path>,
    {
        let path = path.as_ref();
        let file = std::fs::File::create(full_path(path))?;
        serde_json::to_writer(file, &data)?;
        Ok(())
    }
}

#[macro_export]
macro_rules! log {
    ($($arg:tt)*) => {
        {
            use std::io::Write;
            let mut log_file = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open("/tmp/hypr-ipc.log")
                .expect("could not open log file");

            println!($($arg)*);
            writeln!(log_file, $($arg)*).expect("could not write to hypr-ipc.log");
            log_file.flush().expect("could not flush hypr-ipc.log");
        }
    };
}

pub fn kill_wrapped_process(unwrapped_name: &str, signal: &str) {
    let wrapped_name = format!(".{unwrapped_name}-wrapped");

    // kill the wrapped process
    let wrapped_processes = Command::new("pkill")
        .arg("--echo")
        .arg("--signal")
        .arg(signal)
        .arg("--exact")
        .arg(wrapped_name)
        .execute_stdout_lines()
        .expect("could not get wrapped process");

    if !wrapped_processes.is_empty() {
        Command::new("pkill")
            .arg("--signal")
            .arg(signal)
            .arg("--exact")
            .arg(unwrapped_name)
            .output()
            .unwrap_or_else(|_| panic!("failed to kill {unwrapped_name}"));
    }
}

/// swaps the dimenions if the monitor is vertical
pub fn vertical_dimensions(mon: &hyprland::data::Monitor) -> (u32, u32) {
    if mon.transform as u8 % 2 == 1 {
        (mon.height.into(), mon.width.into())
    } else {
        (mon.width.into(), mon.height.into())
    }
}

pub fn find_monitor_by_name(name: &str) -> Option<hyprland::data::Monitor> {
    use hyprland::shared::HyprData;
    hyprland::data::Monitors::get()
        .expect("could not get monitors")
        .iter()
        .find(|mon| mon.name == name)
        .cloned()
}

pub type WorkspacesByMonitor = HashMap<NixMonitorInfo, Vec<i32>>;

/// assign workspaces to their rules if possible, otherwise add them to the other monitors
pub fn rearranged_workspaces<S: ::std::hash::BuildHasher>(
    nix_monitors: &[NixMonitorInfo],
    active_workspaces: &HashMap<String, i32, S>,
) -> WorkspacesByMonitor {
    let mut workspaces_by_mon: WorkspacesByMonitor = HashMap::new();

    // not active, add to the monitor with the least workspaces
    let least_workspaces_mon = nix_monitors
        .iter()
        // only monitors that are still active
        .filter(|mon| active_workspaces.contains_key(&mon.name))
        .min_by_key(|mon| mon.workspaces.len())
        .expect("no monitors were found");

    for mon in nix_monitors {
        if active_workspaces.get(&mon.name).is_some() {
            // active, use current workspaces
            workspaces_by_mon
                .entry(mon.clone())
                .or_default()
                .extend(&mon.workspaces);
        } else {
            workspaces_by_mon
                .entry(least_workspaces_mon.clone())
                .or_default()
                .extend(&mon.workspaces);
        }
    }

    for wksps in workspaces_by_mon.values_mut() {
        wksps.sort_unstable();
    }

    workspaces_by_mon
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rearranged_workspace_remove_monitors() {
        let by_workspace_name = |wksps_by_mon: &WorkspacesByMonitor| -> HashMap<String, Vec<i32>> {
            wksps_by_mon
                .iter()
                .map(|(mon, wksps)| (mon.name.clone(), wksps.clone()))
                .collect()
        };

        let nix_monitors = vec![
            NixMonitorInfo {
                name: "UW".into(),
                workspaces: vec![1, 2, 3, 4, 5],
                ..Default::default()
            },
            NixMonitorInfo {
                name: "VERT".into(),
                workspaces: vec![6, 7],
                ..Default::default()
            },
            NixMonitorInfo {
                name: "PP".into(),
                workspaces: vec![9],
                ..Default::default()
            },
            NixMonitorInfo {
                name: "FWVERT".into(),
                workspaces: vec![8, 10],
                ..Default::default()
            },
        ];

        let active_wksps_vec = [
            ("UW".to_string(), 3),
            ("VERT".to_string(), 7),
            ("PP".to_string(), 8),
            ("FWVERT".to_string(), 10),
        ];

        let remove_monitors = |mons: &[&str]| -> HashMap<String, i32> {
            active_wksps_vec
                .iter()
                .filter(|(name, _)| !mons.contains(&name.as_str()))
                .cloned()
                .collect()
        };

        // sanity check, should be a noop
        assert_eq!(
            by_workspace_name(&rearranged_workspaces(&nix_monitors, &remove_monitors(&[]))),
            HashMap::from([
                ("UW".to_string(), vec![1, 2, 3, 4, 5]),
                ("VERT".to_string(), vec![6, 7]),
                ("PP".to_string(), vec![9]),
                ("FWVERT".to_string(), vec![8, 10]),
            ]),
            "No monitors removed"
        );

        assert_eq!(
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&["FWVERT"])
            )),
            HashMap::from([
                ("UW".to_string(), vec![1, 2, 3, 4, 5]),
                ("VERT".to_string(), vec![6, 7]),
                ("PP".to_string(), vec![8, 9, 10]),
            ]),
            "FWVERT removed"
        );

        assert_eq!(
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&["FWVERT", "PP"])
            )),
            HashMap::from([
                ("UW".to_string(), vec![1, 2, 3, 4, 5]),
                ("VERT".to_string(), vec![6, 7, 8, 9, 10]),
            ]),
            "PP, FWVERT removed"
        );

        assert_eq!(
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&["FWVERT", "PP", "VERT"])
            )),
            HashMap::from([("UW".to_string(), vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),]),
            "VERT, PP, FWVERT removed"
        );

        assert_eq!(
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&["VERT"])
            )),
            HashMap::from([
                ("UW".to_string(), vec![1, 2, 3, 4, 5]),
                ("PP".to_string(), vec![6, 7, 9]),
                ("FWVERT".to_string(), vec![8, 10]),
            ]),
            "VERT removed"
        );
    }
}
