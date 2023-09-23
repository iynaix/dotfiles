use dotfiles_utils::{cmd, get_active_monitors, get_rearranged_workspaces, hypr};

fn main() {
    let active_monitors = get_active_monitors();
    let workspaces = get_rearranged_workspaces(&active_monitors);

    // move workspaces to monitors
    for (mon, wksps) in workspaces.iter() {
        wksps
            .iter()
            .for_each(|wksp| hypr(&["moveworkspacetomonitor", wksp.to_string().as_str(), mon]))
    }

    // focus workspace on monitors
    let primary_workspaces = [1, 7, 9];
    for (_, wksps) in workspaces.iter() {
        // focus current workspace if monitor is already active
        // if let Some(wksp) = active_monitors.get(mon) {
        //     hypr(&["workspace", wksp.to_string().as_str()]);
        //     continue;
        // }

        for wksp in wksps {
            if primary_workspaces.contains(wksp) {
                hypr(&["workspace", wksp.to_string().as_str()]);
                break;
            }
        }
    }

    // focus first / primary monitor
    hypr(&["focusmonitor", workspaces.keys().next().unwrap().as_str()]);

    // launch waybar
    cmd(&["launch-waybar"]);
}