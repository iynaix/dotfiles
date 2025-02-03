use std::collections::HashMap;

use clap::{CommandFactory, Parser};
use common::{
    nixinfo::{NixInfo, NixMonitorInfo},
    rearranged_workspaces,
    rofi::Rofi,
    wallpaper, WorkspacesByMonitor,
};
use dotfiles::{
    cli::{HyprMonitorArgs, MonitorExtend},
    generate_completions,
};
use hyprland::dispatch;
use hyprland::{
    data::Monitors,
    dispatch::{Dispatch, DispatchType, MonitorIdentifier, WorkspaceIdentifier},
    keyword::Keyword,
    shared::HyprData,
};
use itertools::Itertools;

/// mirrors the current display onto the new display
fn mirror_monitors(new_mon: &str) {
    let nix_monitors = NixInfo::new().monitors;

    let primary = nix_monitors.first().expect("no primary monitor found");

    // mirror the primary to the new one
    Keyword::set(
        "monitor",
        format!("{},preferred,auto,1,mirror,{}", primary.name, new_mon),
    )
    .expect("unable to mirror displays");
}

fn move_workspaces_to_monitors(workspaces: &WorkspacesByMonitor) {
    for (mon, wksps) in workspaces {
        for wksp in wksps {
            // note it can error if the workspace is empty and hasnt been created yet
            dispatch!(
                MoveWorkspaceToMonitor,
                WorkspaceIdentifier::Id(*wksp),
                MonitorIdentifier::Name(mon)
            )
            .ok();
        }
    }
}

/// distribute the workspaces evenly across all monitors
fn distribute_workspaces(
    extend_type: &MonitorExtend,
    nix_monitors: &[NixMonitorInfo],
) -> WorkspacesByMonitor {
    let workspaces: Vec<i32> = (1..=10).collect();

    let all_monitors = Monitors::get().expect("could not get monitors");
    let all_monitors = all_monitors
        .iter()
        // putt the nix_monitors first
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

fn main() {
    let args = HyprMonitorArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions("hypr-monitors", &mut HyprMonitorArgs::command(), &shell);
    }

    // --rofi
    if let Some(new_mon) = args.rofi {
        let choices = ["Extend as Primary", "Extend as Secondary", "Mirror"];

        let (sel, _) = Rofi::new(&choices)
            .arg("-lines")
            .arg(choices.len().to_string())
            .run();

        match sel.as_str() {
            "Extend as Primary" => println!("extending as primary"),
            "Extend as Secondary" => println!("extending as secondary"),
            "Mirror" => mirror_monitors(&new_mon),
            _ => {
                eprintln!("No selection made, exiting...");
                std::process::exit(1);
            }
        };

        std::process::exit(0);
    }

    // --mirror
    if let Some(new_mon) = args.mirror {
        mirror_monitors(&new_mon);
    }

    // distribute workspaces per monitor
    let nix_monitors = NixInfo::new().monitors;
    let workspaces = if let Some(extend_type) = args.extend {
        // --extend
        distribute_workspaces(&extend_type, &nix_monitors)
    } else {
        let active_workspaces: HashMap<_, _> = Monitors::get()
            .expect("could not get monitors")
            .iter()
            .map(|mon| (mon.name.clone(), mon.active_workspace.id))
            .collect();

        rearranged_workspaces(&nix_monitors, &active_workspaces)
    };

    move_workspaces_to_monitors(&workspaces);

    // reload wallpaper
    wallpaper::reload(None);
}
