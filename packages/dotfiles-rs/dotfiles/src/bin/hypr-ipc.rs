use common::nixjson::NixJson;
use dotfiles::{cli::WmMonitorArgs, monitors::wm_monitors};
use hyprland::{
    data::{Clients, Monitor, WorkspaceRules, Workspaces},
    event_listener::EventListener,
    keyword::Keyword,
    shared::{HyprData, WorkspaceType},
};
use itertools::Itertools;

/// returns the monitor and if the workspace currently exists
fn monitor_for_workspace(wksp_name: &str) -> Option<Monitor> {
    let monitors = hyprland::data::Monitors::get().expect("could not get monitors");
    let mon_name = if let Some(wksp) = Workspaces::get()
        .expect("could not get workspaces")
        .iter()
        .find(|w| w.name == wksp_name)
    {
        wksp.monitor.to_string()
    } else {
        // workspace is empty and doesn't exist yet, search workspace rules for the monitor
        let wksp_rules = WorkspaceRules::get().expect("could not get workspace rules");

        let rule_monitor = wksp_rules
            .iter()
            .find_map(|rule| {
                (rule.workspace_string == wksp_name).then(|| {
                    rule.monitor
                        .as_ref()
                        .expect("no monitor found for workspace rule")
                })
            })
            .expect("no rule found for monitor");

        rule_monitor.to_string()
    };

    monitors.into_iter().find(|mon| mon.name == mon_name)
}

/// set random split ratio to prevent oled burn in
fn set_split_ratio(nstack: bool, split_ratio: f32) {
    let keyword_path = if nstack {
        "plugin:nstack:layout:mfact"
    } else {
        "master:mfact"
    };

    Keyword::set(keyword_path, split_ratio.to_string()).expect("unable to set mfact");
}

/// sets split ratio if there are 2 windows
fn split_for_workspace(wksp_name: &str, nstack: bool) {
    let wksp = &wksp_name.replace(" silent", "");

    // check if oled
    if monitor_for_workspace(wksp)
        .filter(|mon| mon.description.contains("AW3423DW"))
        .is_none()
    {
        return;
    }

    let wksp_id: i32 = wksp.parse().unwrap_or_default();
    let clients = Clients::get().expect("could not get clients");
    let clients = clients
        .iter()
        .filter(|c| c.workspace.id == wksp_id)
        .collect_vec();

    // floating window, don't do anything
    if clients.iter().any(|c| c.floating) {
        return;
    }

    let num_windows = clients.len();
    let split_ratio = if num_windows == 2 {
        fastrand::f32().mul_add(0.1, 0.4)
    } else if nstack {
        0.0
    } else {
        0.5
    };

    set_split_ratio(nstack, split_ratio);
}

fn main() -> hyprland::Result<()> {
    let is_desktop = NixJson::new().host == "desktop";
    let nstack = Keyword::get("general:layout")?.value.to_string().as_str() == "nstack";

    let mut listener = EventListener::new();

    // only care about dynamic split ratios for oled
    if is_desktop {
        listener.add_window_opened_handler(move |data| {
            // TODO: cannot resize tiled windows?
            /*
            if ev_args[2] == "mpv" {
                if let Some(win) = Client::by_id(&ev_args[0]) {
                    let (mon, _) = Monitor::by_workspace(&ev_args[1]);

                    let (win_w, win_h) = win.size;
                    let is_full_width = mon.width - win_w < 60;
                    let is_full_height = mon.height - win_h < 60;

                    // single window, ignore
                    if is_full_width {
                        continue;
                    }

                    if is_full_height {
                        // resize width to fit 16:9 aspect ratio
                        let new_width = win_h * 16 / 9 - win_w;
                        let resize_params = format!("{new_width} {win_h}");

                        hypr(["focuswindow", &win.address]);
                        hypr(["resizeactive", &resize_params]);
                    }
                }
            }
            */

            split_for_workspace(&data.workspace_name, nstack);
        });

        listener.add_window_moved_handler(move |data| {
            if let WorkspaceType::Regular(wksp) = data.workspace_name {
                split_for_workspace(&wksp, nstack);
            }
        });

        listener.add_window_closed_handler(move |address| {
            if let Some(wksp_id) = Clients::get()
                .expect("could not get clients")
                .iter()
                .find_map(|c| (c.address == address).then_some(c.workspace.id))
            {
                split_for_workspace(&wksp_id.to_string(), nstack);
            }
        });
    }

    listener.add_monitor_added_handler(|mon| {
        // single monitor in config; is laptop
        if NixJson::new().monitors.len() == 1 {
            // --rofi
            wm_monitors(WmMonitorArgs {
                rofi: Some(mon.name),
                ..Default::default()
            });
        } else {
            // desktop, redistribute workspaces
            wm_monitors(WmMonitorArgs::default());
        }
    });

    listener.add_monitor_removed_handler(|_mon| {
        // redistribute workspaces
        wm_monitors(WmMonitorArgs::default());
    });

    listener.start_listener()
}
