use clap::Parser;
use dotfiles_utils::{cli::HyprMonitorArgs, cmd, hypr, monitor::Monitor, nixinfo::NixInfo};

fn main() {
    let args = HyprMonitorArgs::parse();

    // single monitor in config probably means laptop, so distribute them
    let workspaces = if NixInfo::before().monitors.len() == 1 {
        Monitor::distribute_workspaces(matches!(args.extend.as_deref(), Some("primary")))
    } else {
        Monitor::rearranged_workspaces()
    };

    // move workspaces to monitors
    for (mon, wksps) in workspaces.iter() {
        wksps
            .iter()
            .for_each(|wksp| hypr(&["moveworkspacetomonitor", &wksp.to_string(), mon]))
    }

    // focus workspace on monitors
    let primary_workspaces = [1, 7, 9];
    for (_, wksps) in workspaces.iter() {
        // focus current workspace if monitor is already active
        // if let Some(wksp) = active_monitors.get(mon) {
        //     hypr(&["workspace", &wksp.to_string()]);
        //     continue;
        // }

        for wksp in wksps {
            if primary_workspaces.contains(wksp) {
                hypr(&["workspace", &wksp.to_string()]);
                break;
            }
        }
    }

    // focus first / primary monitor
    hypr(&["focusmonitor", (workspaces.keys().next().unwrap())]);

    // reload wallpaper
    cmd(["hypr-wallpaper", "--reload"]);
}
