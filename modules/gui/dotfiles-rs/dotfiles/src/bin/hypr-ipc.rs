use color_eyre::eyre::Result;
use common::{is_hyprland, nixjson::NixJson};
use dotfiles::{cli::WmMonitorArgs, monitors::hypr_monitors};
use hyprland::event_listener::EventListener;

fn main() -> Result<()> {
    // no-op if not hyprland
    if !is_hyprland() {
        return Ok(());
    }

    let mut listener = EventListener::new();

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

    listener.start_listener()?;

    Ok(())
}
