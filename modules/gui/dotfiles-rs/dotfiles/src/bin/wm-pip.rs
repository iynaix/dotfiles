use color_eyre::eyre::{OptionExt, Result};
use common::{
    is_umbriel,
    umbriel::{UmbrielMonitor, UmbrielWindow},
};
use execute::{Execute, command_args};

// TODO: umbriel actions cannot currently position a floating window
#[allow(unused)]
fn umbriel_pip() -> Result<()> {
    let focused = UmbrielWindow::focused()?;
    let mon = UmbrielMonitor::focused()?;
    let mode = mon.current_mode().ok_or_eyre("No current monitor mode")?;

    // use monitor width even on vertical monitors
    let (mon_w, mon_h) = if mon.is_vertical() {
        (mode.height, mode.width)
    } else {
        (mode.width, mode.height)
    };

    // figure out dimensions of target window with aspect ratio 16:9
    let target_w = 0.2 * f64::from(mon_w);
    let target_h = target_w / 16.0 * 9.0;

    if !focused.floating {
        const PADDING: i32 = 30; // target distance from corner of screen

        command_args!("umbriel", "msg", "window-toggle-floating").execute()?;

        let win_w = f64::from(focused.w);
        let win_h = f64::from(focused.h);

        let delta_w = -(1.0 - target_w / win_w);
        let delta_h = -(1.0 - target_h / win_h);

        command_args!(
            "umbriel",
            "msg",
            // format!("window-set-primary-extent:{delta_w}")
            "window-modify-width-right",
            delta_w.to_string()
        )
        .execute()?;

        command_args!(
            "umbriel",
            "msg",
            // format!("window-set-secondary-extent:{delta_h}")
            "window-modify-height-down",
            delta_h.to_string()
        )
        .execute()?;

        command_args!(
            "umbriel",
            "msg",
            "window-move-to",
            "bottom_right",
            PADDING.to_string(),
            PADDING.to_string(),
            "--window",
            focused.id
        )
        .execute()?;
    }

    Ok(())
}

fn main() -> Result<()> {
    if is_umbriel() {
        umbriel_pip()?;
    }

    Ok(())
}
