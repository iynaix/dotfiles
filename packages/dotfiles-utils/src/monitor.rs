use crate::{hypr_json, nixinfo::NixInfo, WorkspaceId};
use serde::Deserialize;
use std::collections::HashMap;

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

    /// distribute the workspaces evenly across all monitors
    pub fn distribute_workspaces(extend_as_primary: bool) -> HashMap<String, Vec<i32>> {
        let workspaces: Vec<i32> = (1..10).collect();

        let mut all_monitors = Monitor::monitors();
        let nix_monitors = NixInfo::before().monitors;

        // sort all_monitors, putting the nix_monitors first
        all_monitors.sort_by_key(|a| {
            let is_base_monitor = nix_monitors.iter().any(|m| m.name == a.name);
            (
                if extend_as_primary {
                    is_base_monitor
                } else {
                    !is_base_monitor
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
                    + if i < workspaces.len() % all_monitors.len() {
                        1
                    } else {
                        0
                    };
                let end = start + len;
                let wksps = &workspaces[start..end];
                start += len;

                (mon.name.clone(), wksps.to_vec())
            })
            .collect()
    }
}
