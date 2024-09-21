use dotfiles::{find_monitor_by_name, nixinfo::NixInfo};
use execute::Execute;
use hyprland::{
    data::{Clients, Monitor, WorkspaceRules, Workspaces},
    event_listener::EventListener,
    keyword::Keyword,
    shared::HyprData,
};

/// returns the monitor and if the workspace currently exists
fn monitor_for_workspace(wksp_name: &str) -> Option<Monitor> {
    if let Some(wksp) = Workspaces::get()
        .expect("could not get workspaces")
        .iter()
        .find(|w| w.name == wksp_name)
    {
        find_monitor_by_name(&wksp.monitor)
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

        find_monitor_by_name(rule_monitor)
    }
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
    let Some(mon) = monitor_for_workspace(wksp) else {
        return;
    };

    // check if oled
    if !mon.description.contains("AW3423DW") {
        return;
    }

    let wksp_id: i32 = wksp.parse().unwrap_or_default();
    let clients = Clients::get().expect("could not get clients");
    let clients: Vec<_> = clients
        .iter()
        .filter(|c| c.workspace.id == wksp_id)
        .collect();

    // floating window, don't do anything
    if clients.iter().any(|c| c.floating) {
        return;
    }

    let num_windows = clients.len();
    let split_ratio = if num_windows == 2 {
        rand::random::<f32>().mul_add(0.1, 0.4)
    } else if nstack {
        0.0
    } else {
        0.5
    };

    set_split_ratio(nstack, split_ratio);
}

fn main() -> hyprland::Result<()> {
    let is_desktop = NixInfo::before().host == "desktop";
    let nstack = Keyword::get("general:layout")?.value.to_string().as_str() == "nstack";

    let mut event_listener = EventListener::new();

    // only care about dynamic split ratios for oled
    if is_desktop {
        event_listener.add_window_open_handler(move |data| {
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

        event_listener.add_window_moved_handler(move |data| {
            split_for_workspace(&data.workspace_name, nstack);
        });

        event_listener.add_window_close_handler(move |address| {
            if let Some(wksp_id) = Clients::get()
                .expect("could not get clients")
                .iter()
                .find_map(|c| (c.address == address).then_some(c.workspace.id))
            {
                split_for_workspace(&wksp_id.to_string(), nstack);
            }
        });
    }

    event_listener.add_monitor_added_handler(|mon| {
        // single monitor in config; is laptop
        if NixInfo::before().monitors.len() == 1 {
            execute::command!("hypr-monitors")
                .arg("--rofi")
                .arg(mon)
                .execute()
                .expect("failed to run rofi-monitors");
        } else {
            // desktop, redistribute workspaces
            execute::command!("hypr-monitors")
                .execute()
                .expect("failed to run hypr-monitors");
        }
    });

    event_listener.add_monitor_removed_handler(|_mon| {
        // redistribute workspaces
        execute::command!("hypr-monitors")
            .execute()
            .expect("failed to run hypr-monitors");
    });

    event_listener.start_listener()
}
