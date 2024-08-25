use clap::Parser;
use dotfiles_utils::{
    cli::HyprMonitorArgs,
    hypr,
    monitor::{Monitor, WorkspacesByMonitor},
    rofi::Rofi,
};
use execute::Execute;

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

fn move_workspaces_to_monitors(workspaces: &WorkspacesByMonitor) {
    // move workspaces to monitors
    for (mon, wksps) in workspaces {
        wksps
            .iter()
            .for_each(|wksp| hypr(["moveworkspacetomonitor", &wksp.to_string(), mon]));
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
                hypr(["workspace", &wksp.to_string()]);
                break;
            }
        }
    }

    // focus first / primary monitor
    hypr([
        "focusmonitor",
        (workspaces.keys().next().expect("primary monitor not found")),
    ]);

    reload_wallpaper();
}

fn main() {
    let args = HyprMonitorArgs::parse();

    // --rofi
    if let Some(new_mon) = args.rofi {
        let choices = ["Extend as Primary", "Extend as Secondary", "Mirror"];

        let rofi = Rofi::new("rofi-menu-noinput.rasi", &choices);
        let mut cmd = rofi.command();
        cmd.arg("-lines").arg(choices.len().to_string());

        let selected = rofi.run(&mut cmd);
        match selected.as_str() {
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

    move_workspaces_to_monitors(&workspaces);
}
