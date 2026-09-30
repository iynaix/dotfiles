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

    command_args!("umbriel", "msg", "window-toggle-floating").execute()?;
    command_args!("umbriel", "msg", "window-toggle-pinned").execute()?;

    if !focused.floating {
        const PADDING: i32 = 30; // target distance from corner of screen

        let win_w = f64::from(focused.w);
        let win_h = f64::from(focused.h);

        let w_frac = target_w / win_w;
        let h_frac = target_h / win_h;

        command_args!(
            "umbriel",
            "msg",
            format!("window-set-primary-extent:{w_frac}")
        )
        .execute()?;
        command_args!(
            "umbriel",
            "msg",
            format!("window-set-secondary-extent:{h_frac}")
        )
        .execute()?;

        let mon_bottom = mon.position.y + mon_h;
        let mon_right = mon.position.x + mon_w;

        /*
        let delta_x = mon_right - PADDING - target_w as i32 - activewindow.at.0 as u32;
        let delta_y = mon_bottom - PADDING - target_h as i32 - activewindow.at.1 as u32;

        let lua_dispatch =
            format!("hl.dsp.window.move({{ relative = true, x = {delta_x}, y = {delta_y} }})");
        */
    }

    Ok(())
}

fn main() -> Result<()> {
    if is_umbriel() {
        umbriel_pip()?;
    }

    Ok(())
}
