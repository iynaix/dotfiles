use color_eyre::eyre::{OptionExt, Result};
use execute::Execute;
use nixjson::NixMonitor;

use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

pub mod nixjson;
pub mod rofi;
pub mod umbriel;
pub mod wallpaper;

pub fn full_path<P>(p: P) -> PathBuf
where
    P: AsRef<std::path::Path>,
{
    let path = p.as_ref();

    path.to_str()
        .and_then(|p| p.strip_prefix("~/"))
        .and_then(|p| dirs::home_dir().map(|d| d.join(p)))
        .unwrap_or_else(|| PathBuf::from(path))
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

pub fn filename<P>(path: P) -> Option<String>
where
    P: AsRef<Path> + std::fmt::Debug,
{
    Some(path.as_ref().file_name()?.to_str()?.to_string())
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

pub fn is_hyprland() -> bool {
    std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default() == "Hyprland"
}

pub fn is_umbriel() -> bool {
    std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default() == "umbriel"
}

/// swaps the dimensions if the monitor is vertical
pub fn vertical_dimensions(mon: &hyprland::data::Monitor) -> (u32, u32) {
    if mon.transform as u8 % 2 == 1 {
        (mon.height.into(), mon.width.into())
    } else {
        (mon.width.into(), mon.height.into())
    }
}

pub type WorkspacesByMonitor = HashMap<String, Vec<i32>>;

/// assign workspaces to their rules if possible, otherwise add them to the other monitors
pub fn rearranged_workspaces<S: ::std::hash::BuildHasher>(
    nix_monitors: &[NixMonitor],
    active_workspaces: &HashMap<String, i32, S>,
) -> Result<WorkspacesByMonitor> {
    let mut workspaces_by_mon: WorkspacesByMonitor = HashMap::new();

    for mon in nix_monitors {
        if active_workspaces.get(&mon.name).is_some() {
            // active, use current workspaces
            workspaces_by_mon
                .entry(mon.name.clone())
                .or_default()
                .extend(&mon.workspaces);
        } else {
            // not active, add to the monitor with the least workspaces
            let least_workspaces_mon = nix_monitors
                .iter()
                // only monitors that are still active
                .filter(|mon| active_workspaces.contains_key(&mon.name))
                .min_by_key(|mon| mon.workspaces.len())
                .ok_or_eyre("No monitors were found")?;

            workspaces_by_mon
                .entry(least_workspaces_mon.name.clone())
                .or_default()
                .extend(&mon.workspaces);
        }
    }

    for wksps in workspaces_by_mon.values_mut() {
        wksps.sort_unstable();
    }

    Ok(workspaces_by_mon)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rearranged_workspace_remove_monitors() -> Result<()> {
        let by_workspace_name = |wksps_by_mon: &WorkspacesByMonitor| -> HashMap<String, Vec<i32>> {
            wksps_by_mon
                .iter()
                .map(|(mon_name, wksps)| (mon_name.clone(), wksps.clone()))
                .collect()
        };

        let nix_monitors = vec![
            NixMonitor {
                name: "UW".into(),
                workspaces: vec![1, 2, 3, 4, 5],
                ..Default::default()
            },
            NixMonitor {
                name: "VERT".into(),
                workspaces: vec![6, 7],
                ..Default::default()
            },
            NixMonitor {
                name: "PP".into(),
                workspaces: vec![9],
                ..Default::default()
            },
            NixMonitor {
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
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&[])
            )?),
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
            )?),
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
            )?),
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
            )?),
            HashMap::from([("UW".to_string(), vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),]),
            "VERT, PP, FWVERT removed"
        );

        assert_eq!(
            by_workspace_name(&rearranged_workspaces(
                &nix_monitors,
                &remove_monitors(&["VERT"])
            )?),
            HashMap::from([
                ("UW".to_string(), vec![1, 2, 3, 4, 5]),
                ("PP".to_string(), vec![6, 7, 9]),
                ("FWVERT".to_string(), vec![8, 10]),
            ]),
            "VERT removed"
        );

        Ok(())
    }
}
