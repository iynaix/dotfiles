use clap::{value_parser, CommandFactory, Parser};
use dotfiles::{
    generate_completions,
    monitor::{Monitor, MonitorExtend, WorkspacesByMonitor},
    rofi::Rofi,
    ShellCompletion,
};
use execute::Execute;
use hyprland::dispatch::{
    Dispatch,
    DispatchType::{self, FocusMonitor, MoveWorkspaceToMonitor},
    MonitorIdentifier, WorkspaceIdentifier, WorkspaceIdentifierWithSpecial,
};

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

// reload wallpaper
fn reload_wallpaper() {
    execute::command!("hypr-wallpaper --reload")
        .execute()
        .expect("failed to reload wallpaper");
}

fn mirror_monitors(new_mon: &str) {
    Monitor::mirror_to(new_mon);
    reload_wallpaper();
}

fn move_workspaces_to_monitors(
    workspaces: &WorkspacesByMonitor,
) -> Result<(), hyprland::shared::HyprError> {
    // move workspaces to monitors
    for (mon, wksps) in workspaces {
        for wksp in wksps {
            Dispatch::call(MoveWorkspaceToMonitor(
                WorkspaceIdentifier::Id(*wksp),
                MonitorIdentifier::Name(mon),
            ))?;
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
                Dispatch::call(DispatchType::Workspace(WorkspaceIdentifierWithSpecial::Id(
                    *wksp,
                )))?;
                break;
            }
        }
    }

    // focus first / primary monitor
    Dispatch::call(FocusMonitor(MonitorIdentifier::Name(
        workspaces.keys().next().expect("primary monitor not found"),
    )))?;

    reload_wallpaper();

    Ok(())
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
        std::process::exit(0);
    }

    // distribute workspaces per monitor
    let workspaces = match args.extend {
        // --extend
        Some(extend_type) => Monitor::distribute_workspaces(&extend_type),
        // no args, fall through
        _ => Monitor::rearranged_workspaces(),
    };

    move_workspaces_to_monitors(&workspaces).expect("failed to move workspaces to monitors");
}
