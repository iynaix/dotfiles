use crate::{hypr_json, nixinfo::NixInfo, Workspace, WorkspaceId};
use clap::ValueEnum;
use serde::Deserialize;
use std::collections::HashMap;

#[allow(clippy::module_name_repetitions)]
#[derive(ValueEnum, Debug, Clone)]
pub enum MonitorExtend {
    Primary,
    Secondary,
}

#[allow(clippy::module_name_repetitions)]
pub type WorkspacesByMonitor = HashMap<String, Vec<i32>>;

#[derive(Clone, Default, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceRule {
    #[serde(rename = "workspaceString")]
    pub workspace: String,
    pub monitor: String,
}

#[derive(Clone, Default, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Monitor {
    pub id: i32,
    pub name: String,
    pub model: String,
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
    pub active_workspace: WorkspaceId,
    pub focused: bool,
    pub transform: i8,
}

impl Monitor {
    pub const fn is_vertical(&self) -> bool {
        matches!(self.transform, 1 | 3 | 5 | 7)
    }

    pub const fn is_ultrawide(&self) -> bool {
        self.width >= 3440
    }

    pub fn is_oled(&self) -> bool {
        self.model.contains("AW3423DW")
    }

    pub const fn orientation(&self) -> &str {
        if self.is_vertical() {
            "orientationtop"
        } else {
            "orientationleft"
        }
    }

    pub const fn stacks(&self) -> i32 {
        if self.is_ultrawide() || self.is_vertical() {
            3
        } else {
            2
        }
    }

    pub fn dimension_str(&self) -> String {
        format!("{}x{}", self.width, self.height)
    }

    pub fn monitors() -> Vec<Self> {
        hypr_json::<Vec<Self>>("monitors")
            .iter()
            .map(|mon| {
                if mon.is_vertical() {
                    Self {
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

    pub fn focused() -> Self {
        Self::monitors()
            .into_iter()
            .find(|mon| mon.focused)
            .expect("no focused monitor found")
    }

    pub fn active_workspaces() -> HashMap<String, i32> {
        Self::monitors()
            .into_iter()
            .map(|mon| (mon.name, mon.active_workspace.id))
            .collect()
    }

    /// returns the monitor and if the workspace currently exists
    pub fn by_workspace(wksp: &str) -> (Self, bool) {
        if let Some(wksp) = Workspace::by_name(wksp) {
            (wksp.monitor(), true)
        } else {
            // workspace is empty and doesn't exist yet, search workspace rules for the monitor
            let workspace_rules: Vec<WorkspaceRule> = hypr_json("workspacerules");

            let wksp_rule = workspace_rules
                .into_iter()
                .find(|rule| rule.workspace == wksp)
                .unwrap_or_else(|| panic!("workspace {wksp:?} not found within workspace rules"));

            let mon = Self::monitors()
                .into_iter()
                .find(|mon| mon.name == wksp_rule.monitor)
                .unwrap_or_else(|| {
                    panic!(
                        "monitor {} not found from workspace rules",
                        &wksp_rule.monitor
                    )
                });

            (mon, false)
        }
    }

    pub fn rearranged_workspaces() -> WorkspacesByMonitor {
        let nix_monitors = NixInfo::before().monitors;
        let active_workspaces = Self::active_workspaces();

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
                                    .extend(&mon.workspaces);
                            }
                        }
                    }
                }
                acc
            })
    }

    /// distribute the workspaces evenly across all monitors
    pub fn distribute_workspaces(extend_type: &MonitorExtend) -> WorkspacesByMonitor {
        let workspaces: Vec<i32> = (1..=10).collect();

        let mut all_monitors = Self::monitors();
        let nix_monitors = NixInfo::before().monitors;

        // sort all_monitors, putting the nix_monitors first
        all_monitors.sort_by_key(|a| {
            let is_base_monitor = nix_monitors.iter().any(|m| m.name == a.name);
            (
                match extend_type {
                    MonitorExtend::Primary => is_base_monitor,
                    MonitorExtend::Secondary => !is_base_monitor,
                },
                a.id,
            )
        });

        let mut start = 0;
        all_monitors
            .iter()
            .enumerate()
            .map(|(i, mon)| {
                let len = workspaces.len() / all_monitors.len()
                    + usize::from(i < workspaces.len() % all_monitors.len());
                let end = start + len;
                let wksps = &workspaces[start..end];
                start += len;

                (mon.name.clone(), wksps.to_vec())
            })
            .collect()
    }

    /// mirrors the current display onto the new display
    pub fn mirror_to(new_mon: &str) {
        let nix_monitors = NixInfo::before().monitors;

        let primary = nix_monitors.first().expect("no primary monitor found");

        // mirror the primary to the new one
        execute::command_args!(
            "hyprctl",
            "keyword",
            "monitor",
            &format!("{},preferred,auto,1,mirror,{}", primary.name, new_mon)
        );

        // hyprctl keyword monitor HDMI-A-1,mirror,eDP-1
    }
}
