use clap::{value_parser, CommandFactory, Parser, ValueEnum};
use dotfiles::{
    generate_completions, nixinfo::NixInfo, rearranged_workspaces, rofi::Rofi, ShellCompletion,
    WorkspacesByMonitor,
};
use execute::Execute;
use hyprland::dispatch;
use hyprland::{
    data::Monitors,
    dispatch::{
        Dispatch, DispatchType, MonitorIdentifier, WorkspaceIdentifier,
        WorkspaceIdentifierWithSpecial,
    },
    keyword::Keyword,
    shared::{HyprData, HyprDataVec},
};

#[derive(ValueEnum, Debug, Clone)]
pub enum MonitorExtend {
    Primary,
    Secondary,
}

#[derive(Parser, Debug)]
#[command(name = "hypr-monitors", about = "Re-arranges workspaces to monitor")]
/// Utilities for working with adding or removing monitors in hyprland
/// Without arguments, it redistributes the workspaces across all monitors
pub struct HyprMonitorArgs {
    #[arg(
        long,
        value_parser = value_parser!(MonitorExtend),
        help = "set new monitor(s) to be primary or secondary"
    )]
    pub extend: Option<MonitorExtend>,

    #[arg(long, name = "MONITOR", action, help = "mirrors the primary monitor")]
    pub mirror: Option<String>,

    // show rofi menu for selecting monitor
    #[arg(long, action, help = "show rofi menu for monitor options")]
    pub rofi: Option<String>,

    #[arg(
        long,
        value_enum,
        help = "type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

/// mirrors the current display onto the new display
fn mirror_monitors(new_mon: &str) {
    let nix_monitors = NixInfo::before().monitors;

    let primary = nix_monitors.first().expect("no primary monitor found");

    // mirror the primary to the new one
    Keyword::set(
        "monitor",
        format!("{},preferred,auto,1,mirror,{}", primary.name, new_mon),
    )
    .expect("unable to mirror displays");
}

fn move_workspaces_to_monitors(
    workspaces: &WorkspacesByMonitor,
) -> Result<(), hyprland::shared::HyprError> {
    // move workspaces to monitors
    for (mon, wksps) in workspaces {
        for wksp in wksps {
            // note it can error if the workspace is empty has not been created yet
            dispatch!(
                MoveWorkspaceToMonitor,
                WorkspaceIdentifier::Id(*wksp),
                MonitorIdentifier::Name(mon)
            )
            .ok();
        }
    }

    // focus workspace on monitors
    let primary_workspaces = [1, 7, 9];
    for wksps in workspaces.values() {
        // focus current workspace if monitor is already active
        // if let Some(wksp) = active_monitors.get(mon) {
        //     hypr(["workspace", &wksp.to_string()]);
        //     continue;
        // }

        for wksp in wksps {
            if primary_workspaces.contains(wksp) {
                dispatch!(Workspace, WorkspaceIdentifierWithSpecial::Id(*wksp,))?;
                break;
            }
        }
    }

    // focus first / primary monitor
    dispatch!(
        FocusMonitor,
        MonitorIdentifier::Name(workspaces.keys().next().expect("primary monitor not found"),)
    )?;

    Ok(())
}

/// distribute the workspaces evenly across all monitors
fn distribute_workspaces(extend_type: &MonitorExtend) -> WorkspacesByMonitor {
    let workspaces: Vec<i32> = (1..=10).collect();

    let mut all_monitors = Monitors::get().expect("could not get monitors").to_vec();
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
    let workspaces = match args.extend {
        // --extend
        Some(extend_type) => distribute_workspaces(&extend_type),
        // no args, fall through
        _ => rearranged_workspaces(),
    };

    move_workspaces_to_monitors(&workspaces).expect("failed to move workspaces to monitors");

    // reload wallpaper
    execute::command!("hypr-wallpaper --reload")
        .execute()
        .expect("failed to reload wallpaper");
}
