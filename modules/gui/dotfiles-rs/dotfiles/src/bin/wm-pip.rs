use common::is_hyprland;
use execute::Execute;

fn hyprland_pip() -> Result<(), Box<dyn std::error::Error>> {
    use common::vertical_dimensions;
    use hyprland::{
        data::{Client, Monitor},
        shared::{HyprDataActive, HyprDataActiveOptional},
    };

    let active = Client::get_active()?.expect("no active window");
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
    if !active.floating {
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

fn main() -> Result<(), Box<dyn std::error::Error>> {
    if is_hyprland() {
        hyprland_pip()?;
    }

    Ok(())
}
