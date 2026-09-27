use color_eyre::eyre::Result;
use common::{is_hyprland, nixjson::NixJson};
use dotfiles::{cli::WmMonitorArgs, monitors::hypr_monitors};
use hyprland::{
    data::{Clients, Monitor, WorkspaceRules, Workspaces},
    event_listener::EventListener,
    keyword::Keyword,
    shared::{HyprData, WorkspaceType},
};
use itertools::Itertools;

/// returns the monitor and if the workspace currently exists
fn monitor_for_workspace(wksp_name: &str) -> Option<Monitor> {
    let monitors = hyprland::data::Monitors::get().ok()?;
    let mon_name = if let Some(wksp) = Workspaces::get().ok()?.iter().find(|w| w.name == wksp_name)
    {
        wksp.monitor.clone()
    } else {
        // workspace is empty and doesn't exist yet, search workspace rules for the monitor
        let wksp_rules = WorkspaceRules::get().ok()?;

        let rule_monitor = wksp_rules
            .iter()
            .find(|rule| rule.workspace_string == wksp_name)?
            .monitor
            .as_ref()?;

        rule_monitor.clone()
    };

    monitors.into_iter().find(|mon| mon.name == mon_name)
}

/// set random split ratio to prevent oled burn in
fn set_split_ratio(nstack: bool, split_ratio: f32) -> Result<()> {
    let keyword_path = if nstack {
        "plugin:nstack:layout:mfact"
    } else {
        "master:mfact"
    };

    Keyword::set(keyword_path, split_ratio.to_string())?;

    Ok(())
}

/// sets split ratio if there are 2 windows
fn split_for_workspace(wksp_name: &str, nstack: bool) -> Result<()> {
    let wksp = &wksp_name.replace(" silent", "");

    // check if oled
    if monitor_for_workspace(wksp)
        .as_ref()
        .is_none_or(|mon| !mon.description.contains("AW3423DW"))
    {
        return Ok(());
    }

    let wksp_id: i32 = wksp.parse().unwrap_or_default();
    let clients = Clients::get()?;
    let clients = clients
        .iter()
        .filter(|c| c.workspace.id == wksp_id)
        .collect_vec();

    // floating window, don't do anything
    if clients.iter().any(|c| c.floating) {
        return Ok(());
    }

    let num_windows = clients.len();
    let split_ratio = if num_windows == 2 {
        fastrand::f32().mul_add(0.1, 0.4)
    } else if nstack {
        0.0
    } else {
        0.5
    };

    set_split_ratio(nstack, split_ratio)
}

fn main() -> hyprland::Result<()> {
    // no-op if not hyprland
    if !is_hyprland() {
        return Ok(());
    }

    let is_desktop = NixJson::load().host == "desktop";
    let nstack = Keyword::get("general:layout")?.value.to_string().as_str() == "nstack";

    let mut listener = EventListener::new();

    // only care about dynamic split ratios for oled
    if is_desktop {
        listener.add_window_opened_handler(move |data| {
            if let Err(e) = split_for_workspace(&data.workspace_name, nstack) {
                eprintln!("Window opened error: {e}");
            }
        });

        listener.add_window_moved_handler(move |data| {
            if let WorkspaceType::Regular(wksp) = data.workspace_name
                && let Err(e) = split_for_workspace(&wksp, nstack)
            {
                eprintln!("Window moved error: {e}");
            }
        });

        listener.add_window_closed_handler(move |address| {
            if let Ok(clients) = Clients::get()
                && let Some(wksp_id) = clients
                    .iter()
                    .find_map(|c| (c.address == address).then_some(c.workspace.id))
                && let Err(e) = split_for_workspace(&wksp_id.to_string(), nstack)
            {
                eprintln!("Window closed error: {e}");
            }
        });
    }

    listener.add_monitor_added_handler(|mon| {
        // single monitor in config; is laptop
        if NixJson::load().monitors.len() == 1 {
            // --rofi
            if let Err(e) = hypr_monitors(WmMonitorArgs {
                rofi: Some(mon.name),
                ..Default::default()
            }) {
                eprintln!("Monitor added error: {e}");
            }
        } else {
            // desktop, redistribute workspaces
            if let Err(e) = hypr_monitors(WmMonitorArgs::default()) {
                eprintln!("Monitor added error: {e}");
            }
        }
    });

    listener.add_monitor_removed_handler(|_mon| {
        // redistribute workspaces
        if let Err(e) = hypr_monitors(WmMonitorArgs::default()) {
            eprintln!("Monitor removed error: {e}");
        }
    });

    listener.start_listener()
}
