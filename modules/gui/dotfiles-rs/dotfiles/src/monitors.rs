use execute::Execute;
use std::collections::HashMap;

use crate::{
    cli::{MonitorExtend, WmMonitorArgs},
    generate_completions,
};
use clap::CommandFactory;
use color_eyre::eyre::Result;
use common::{
    WorkspacesByMonitor, is_hyprland,
    nixjson::{NixJson, NixMonitor},
    rearranged_workspaces,
    rofi::Rofi,
    wallpaper,
};
use itertools::Itertools;

/// mirrors the current display onto the new display
fn mirror_monitors(new_mon: &str) -> Result<()> {
    let nix_monitors = NixJson::load().monitors;

    if let Some(primary) = nix_monitors.first() {
        // mirror the primary to the new one
        hyprland::keyword::Keyword::set(
            "monitor",
            format!("{},preferred,auto,1,mirror,{}", primary.name, new_mon),
        )?;
    }

    Ok(())
}

fn move_workspaces_to_monitors(workspaces: &WorkspacesByMonitor) -> Result<()> {
    let nix_info_monitors = NixJson::load().monitors;

    for (mon_name, wksps) in workspaces {
        let Some(nix_info_mon) = nix_info_monitors.iter().find(|mon| mon.name == *mon_name) else {
            return Ok(());
        };

        for wksp in wksps {
            {
                // note it can error if the workspace is empty and hasnt been created yet
                let lua_dispatch = format!(
                    r#"hl.dsp.workspace.move({{ workspace = "{wksp}", monitor = "{mon_name}" }})"#
                );
                execute::command_args!("hyprctl", "dispatch", lua_dispatch).execute()?;

                hyprland::keyword::Keyword::set("workspace", nix_info_mon.layoutopts(*wksp))?;
            }
        }
    }

    Ok(())
}

/// distribute the workspaces evenly across all monitors
pub fn distribute_workspaces(
    extend_type: &MonitorExtend,
    nix_monitors: &[NixMonitor],
) -> Result<WorkspacesByMonitor> {
    use hyprland::shared::HyprData;

    let all_monitors = hyprland::data::Monitors::get()?;
    let all_monitors = all_monitors
        .iter()
        // put the nix_monitors first
        .sorted_by_key(|a| {
            let is_base_monitor = nix_monitors.iter().any(|m| m.name == a.name);
            (
                match extend_type {
                    MonitorExtend::Primary => is_base_monitor,
                    MonitorExtend::Secondary => !is_base_monitor,
                },
                a.id,
            )
        })
        .collect_vec();

    let workspaces: Vec<i32> = (1..=10).collect();
    let mut start = 0;
    let ret = all_monitors
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
        .collect();

    Ok(ret)
}

pub fn hypr_monitors(args: WmMonitorArgs) -> Result<()> {
    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("wm-monitors", &mut WmMonitorArgs::command(), &shell);
        return Ok(());
    }

    if !is_hyprland() {
        return Ok(());
    }

    let mut mirror = args.mirror;
    let mut extend_type = args.extend;

    // --rofi
    if let Some(new_mon) = args.rofi {
        let choices = ["Extend as Primary", "Extend as Secondary", "Mirror"];

        let (sel, _) = Rofi::new(&choices)
            .arg("-lines")
            .arg(choices.len().to_string())
            .run()?;

        match sel.as_str() {
            "Extend as Primary" => {
                extend_type = Some(MonitorExtend::Primary);
            }
            "Extend as Secondary" => {
                extend_type = Some(MonitorExtend::Secondary);
            }
            "Mirror" => {
                mirror = Some(new_mon);
            }
            _ => return Ok(()),
        }
    }

    // --mirror
    if let Some(new_mon) = mirror {
        mirror_monitors(&new_mon)?;
    }

    // distribute workspaces per monitor
    let nix_monitors = NixJson::load().monitors;
    let workspaces = if let Some(extend) = extend_type {
        // --extend
        distribute_workspaces(&extend, &nix_monitors)?
    } else {
        use hyprland::shared::HyprData;
        let active_workspaces: HashMap<_, _> = hyprland::data::Monitors::get()?
            .iter()
            .map(|mon| (mon.name.clone(), mon.active_workspace.id))
            .collect();

        rearranged_workspaces(&nix_monitors, &active_workspaces)?
    };

    move_workspaces_to_monitors(&workspaces)?;

    // reload wallpaper
    wallpaper::reload()
}
