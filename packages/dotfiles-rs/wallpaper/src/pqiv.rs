use common::wallpaper;
use itertools::Itertools;

#[cfg_attr(not(feature = "hyprland"), allow(dead_code))]
fn pqiv_hyprland_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    use hyprland::shared::HyprDataActive;
    let mon = hyprland::data::Monitor::get_active().expect("could not get active monitor");

    // handle vertical monitor
    let width = f64::from(mon.width.max(mon.height)) * TARGET_PERCENT;
    // target 16: 9 aspect ratio
    let height = width / 16.0 * 9.0;

    format!("[float;size {} {};center]", width.floor(), height.floor())
}

#[cfg_attr(not(feature = "niri"), allow(dead_code))]
fn niri_window_title() -> String {
    use niri_ipc::{Request, Response, socket::Socket};

    // append monitor name to title so relevant window-rule can match it
    let Ok(Response::FocusedOutput(Some(curr_mon))) = Socket::connect()
        .expect("failed to connect to niri socket")
        .send(Request::FocusedOutput)
        .expect("failed to send FocusedOutput request to niri")
    else {
        panic!("Failed to get focused output from niri");
    };

    format!("wallpaper-rofi-{}", curr_mon.name)
}

#[allow(clippy::module_name_repetitions)]
pub fn show_pqiv() {
    let wall_dir = wallpaper::dir();
    let wall_dir = wall_dir.to_str().expect("invalid wallpaper dir");

    #[cfg(feature = "hyprland")]
    {
        // hyprland allows setting rules while spawning
        let pqiv = format!(
            "{} pqiv --shuffle '{}'",
            pqiv_hyprland_float_rule(),
            &wall_dir
        );

        {
            use hyprland::dispatch::{Dispatch, DispatchType};
            hyprland::dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
        }
    }

    #[cfg(feature = "niri")]
    {
        use execute::Execute;

        // NOTE: niri uses a custom version of pqiv that forces a GDK wayland backend
        // so it doesn't resize on initial spawn via a keybind
        execute::command_args!(
            "pqiv",
            "--shuffle",
            // disable fullscreen on niri as using the GDK wayland backend breaks fullscreen scaling
            "--bind-key",
            "f { nop() }",
            "--window-title",
            niri_window_title()
        )
        .arg(wall_dir)
        .execute()
        .expect("failed to execute pqiv");
    }
}

pub fn show_history() {
    let history = wallpaper::history();
    let history = history
        .iter()
        .skip(1) // skip the current wallpaper
        .map(|(path, _)| path)
        .collect_vec();

    #[cfg(feature = "hyprland")]
    {
        let history = history
            .iter()
            .map(|p| format!("'{}'", p.display()))
            .collect_vec()
            .join(" ");
        let pqiv = format!("{} pqiv {}", pqiv_hyprland_float_rule(), history);

        {
            use hyprland::dispatch::{Dispatch, DispatchType};
            hyprland::dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
        }
    }

    #[cfg(feature = "niri")]
    {
        use execute::Execute;

        let history = history
            .iter()
            .map(|p| p.display().to_string())
            .collect_vec();

        execute::command_args!(
            "pqiv",
            // disable fullscreen on niri as using the GDK wayland backend breaks fullscreen scaling
            "--bind-key",
            "f { nop() }",
            "--window-title",
            niri_window_title()
        )
        .args(history)
        .execute()
        .expect("failed to execute pqiv");
    }
}
