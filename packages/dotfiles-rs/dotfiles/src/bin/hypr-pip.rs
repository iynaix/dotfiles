use common::vertical_dimensions;
use hyprland::dispatch;
use hyprland::{
    data::{Client, Monitor},
    dispatch::{Dispatch, DispatchType, Position},
    shared::{HyprDataActive, HyprDataActiveOptional},
};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let activewindow = Client::get_active()?.expect("no active window");

    let curr_mon = Monitor::get_active()?;

    // figure out dimensions of target window with aspect ratio 16:9
    let target_w = 0.2 * f64::from(curr_mon.width); // use monitor width even on vertical monitors
    let target_h = target_w / 16.0 * 9.0;

    // toggle fake fullscreen?
    // Dispatch::call(if activewindow.fullscreen == FullscreenMode::None {
    //     DispatchType::ToggleFullscreen(FullscreenType::Maximize)
    // } else {
    //     DispatchType::ToggleFullscreen(FullscreenType::NoParam)
    // })?;
    dispatch!(ToggleFloating, None)?;
    Dispatch::call(DispatchType::TogglePin)?;

    // if activewindow.floating {
    //     dispatch!(ToggleFullscreen(FullscreenType::Real))?;
    // } else {
    if !activewindow.floating {
        const PADDING: i32 = 30; // target distance from corner of screen

        #[allow(clippy::cast_possible_truncation)]
        dispatch!(
            ResizeActive,
            Position::Exact(target_w as i16, target_h as i16,)
        )?;

        let activewindow = Client::get_active()?.expect("no active window");

        let (curr_width, curr_height) = vertical_dimensions(&curr_mon);
        let mon_bottom = curr_mon.y + curr_height;
        let mon_right = curr_mon.x + curr_width;

        #[allow(clippy::cast_possible_truncation)]
        let delta_x = mon_right - PADDING - target_w as i32 - i32::from(activewindow.at.0);
        #[allow(clippy::cast_possible_truncation)]
        let delta_y = mon_bottom - PADDING - target_h as i32 - i32::from(activewindow.at.1);

        #[allow(clippy::cast_possible_truncation)]
        dispatch!(MoveActive, Position::Delta(delta_x as i16, delta_y as i16))
            .expect("failed to move active window");
    }

    Ok(())
}
