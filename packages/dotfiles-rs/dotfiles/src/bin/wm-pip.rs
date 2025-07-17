#[cfg(feature = "hyprland")]
fn hyprland_pip() -> Result<(), Box<dyn std::error::Error>> {
    use common::vertical_dimensions;
    use hyprland::dispatch;
    use hyprland::{
        data::{Client, Monitor},
        dispatch::{Dispatch, DispatchType, Position},
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
    dispatch!(ToggleFloating, None)?;
    Dispatch::call(DispatchType::TogglePin)?;

    // if activewindow.floating {
    //     dispatch!(ToggleFullscreen(FullscreenType::Real))?;
    // } else {
    #[allow(clippy::cast_sign_loss)]
    #[allow(clippy::cast_possible_truncation)]
    if !active.floating {
        const PADDING: u32 = 30; // target distance from corner of screen

        #[allow(clippy::cast_possible_truncation)]
        dispatch!(
            ResizeActive,
            Position::Exact(target_w as i16, target_h as i16,)
        )?;

        let activewindow = Client::get_active()?.expect("no active window");

        let (curr_width, curr_height) = vertical_dimensions(&mon);
        let mon_bottom = mon.y as u32 + curr_height;
        let mon_right = mon.x as u32 + curr_width;

        let delta_x = mon_right - PADDING - target_w as u32 - activewindow.at.0 as u32;
        let delta_y = mon_bottom - PADDING - target_h as u32 - activewindow.at.1 as u32;

        #[allow(clippy::cast_possible_truncation)]
        dispatch!(MoveActive, Position::Delta(delta_x as i16, delta_y as i16))
            .expect("failed to move active window");
    }

    Ok(())
}

#[cfg(feature = "niri")]
fn niri_pip() -> Result<(), Box<dyn std::error::Error>> {
    use niri_ipc::{
        Action, LogicalOutput, Output, PositionChange, Request, Response, SizeChange,
        socket::Socket,
    };

    let mut socket = Socket::connect().expect("failed to connect to niri socket");

    let curr_mon = match socket
        .send(Request::FocusedOutput)
        .expect("failed to send FocusedOutput request to niri")
    {
        Ok(Response::FocusedOutput(Some(curr_mon))) => curr_mon,
        Ok(Response::FocusedOutput(None)) => {
            eprintln!("No focused output found.");
            std::process::exit(0);
        }
        _ => panic!("unexpected response from niri, should be FocusedOutput"),
    };

    let Output {
        logical:
            Some(LogicalOutput {
                width: curr_width,
                height: curr_height,
                ..
            }),
        ..
    } = curr_mon
    else {
        panic!("Focused output is disabled!");
    };

    // figure out dimensions of target window with aspect ratio 16:9
    let target_w = 0.2 * f64::from(curr_width.max(curr_height)); // use monitor width even on vertical monitors
    let target_h = target_w / 16.0 * 9.0;

    // toggle fake fullscreen?

    // toggle floating
    socket
        .send(Request::Action(Action::ToggleWindowFloating { id: None }))
        .expect("failed to send ToggleWindowFloating")?;

    let active = match socket
        .send(Request::FocusedWindow)
        .expect("failed to send FocusedWindow request to niri")
    {
        Ok(Response::FocusedWindow(Some(active))) => active,
        Ok(Response::FocusedWindow(None)) => {
            eprintln!("No active window found.");
            std::process::exit(0);
        }
        _ => panic!("unexpected response from niri, should be FocusedWindow"),
    };

    #[allow(clippy::cast_sign_loss)]
    #[allow(clippy::cast_possible_truncation)]
    if active.is_floating {
        const PADDING: f64 = 30.0; // target distance from corner of screen
        const WAYBAR_HEIGHT: f64 = 36.0;

        socket
            .send(Request::Action(Action::SetWindowWidth {
                id: None,
                change: SizeChange::SetFixed(target_w as i32),
            }))
            .expect("failed to send SetWindowWidth")?;
        socket
            .send(Request::Action(Action::SetWindowHeight {
                id: None,
                change: SizeChange::SetFixed(target_h as i32),
            }))
            .expect("failed to send SetWindowHeight")?;

        // TODO: check if waybar is hidden, niri doesn't take into account the exclusion zone
        let is_waybar_hidden = false;

        let final_x = f64::from(curr_width) - PADDING - target_w;
        let final_y = f64::from(curr_height)
            - PADDING
            - target_h
            - if is_waybar_hidden { 0.0 } else { WAYBAR_HEIGHT };

        socket
            .send(Request::Action(Action::MoveFloatingWindow {
                id: None,
                x: PositionChange::SetFixed(final_x),
                y: PositionChange::SetFixed(final_y - 36.0),
            }))
            .expect("failed to send MoveFloatingWindow")?;
    }

    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    #[cfg(feature = "hyprland")]
    hyprland_pip()?;

    #[cfg(feature = "niri")]
    niri_pip()?;

    Ok(())
}
