use common::{
    is_hyprland,
    umbriel::{UmbrielMonitor, UmbrielWindow},
};
use execute::{Execute, command_args};

fn hyprland_pip() -> Result<(), Box<dyn std::error::Error>> {
    use common::vertical_dimensions;
    use hyprland::{
        data::{Client, Monitor},
        shared::{HyprDataActive, HyprDataActiveOptional},
    };

    let focused = Client::get_active()?.expect("no active window");
    let mon = Monitor::get_active()?;

    // figure out dimensions of target window with aspect ratio 16:9
    let target_w = 0.2 * f64::from(mon.width); // use monitor width even on vertical monitors
    let target_h = target_w / 16.0 * 9.0;

    // toggle fake fullscreen?
    // Dispatch::call(if activewindow.fullscreen == FullscreenMode::None {
    //     DispatchType::ToggleFullscreen(FullscreenType::Maximize)
    // } else {
    //     DispatchType::ToggleFullscreen(FullscreenType::NoParam)
    // })?;
    execute::command_args!("hyprctl", "dispatch", "hl.dsp.window.float()").execute()?;
    execute::command_args!("hyprctl", "dispatch", "hl.dsp.window.pin()").execute()?;

    // if activewindow.floating {
    //     dispatch!(ToggleFullscreen(FullscreenType::Real))?;
    // } else {
    if !focused.floating {
        const PADDING: u32 = 30; // target distance from corner of screen

        let lua_dispatch = format!("hl.dsp.window.resize({{ x = {target_w}, y = {target_h} }})");
        execute::command_args!("hyprctl", "dispatch", lua_dispatch).execute()?;

        let activewindow = Client::get_active()?.expect("no active window");

        let (curr_width, curr_height) = vertical_dimensions(&mon);
        let mon_bottom = mon.y as u32 + curr_height;
        let mon_right = mon.x as u32 + curr_width;

        let delta_x = mon_right - PADDING - target_w as u32 - activewindow.at.0 as u32;
        let delta_y = mon_bottom - PADDING - target_h as u32 - activewindow.at.1 as u32;

        let lua_dispatch =
            format!("hl.dsp.window.move({{ relative = true, x = {delta_x}, y = {delta_y} }})");
        execute::command_args!("hyprctl", "dispatch", lua_dispatch).execute()?;
    }

    Ok(())
}

// TODO: umbriel actions cannot currently position a floating window
#[allow(unused)]
fn umbriel_pip() -> Result<(), Box<dyn std::error::Error>> {
    let focused = UmbrielWindow::focused().ok_or("No focused window")?;
    let mon = UmbrielMonitor::focused().ok_or("No focused monitor")?;
    let mode = mon.current_mode().ok_or("No current monitor mode")?;

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

        // let w_frac = target_w / win_w * (if target_w > win_w { -1.0 } else { 1.0 });
        // let h_frac = target_h / win_h * (if target_h > win_h { -1.0 } else { 1.0 });

        let w_frac = target_w / win_w;
        let h_frac = target_h / win_h;

        command_args!("umbriel", "msg", format!("window-set-width:{w_frac}")).execute()?;
        command_args!("umbriel", "msg", format!("window-set-height:{h_frac}")).execute()?;

        let mon_bottom = mon.position.y + mon_h;
        let mon_right = mon.position.x + mon_w;

        /*
        let delta_x = mon_right - PADDING - target_w as i32 - activewindow.at.0 as u32;
        let delta_y = mon_bottom - PADDING - target_h as i32 - activewindow.at.1 as u32;

        let lua_dispatch =
            format!("hl.dsp.window.move({{ relative = true, x = {delta_x}, y = {delta_y} }})");
        execute::command_args!("hyprctl", "dispatch", lua_dispatch).execute()?;
        */
    }

    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    if is_hyprland() {
        hyprland_pip()?;
    }

    Ok(())
}
