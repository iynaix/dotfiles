use crate::{cli::WallpaperFilterArgs, filter_images_by_faces};
use common::{
    is_hyprland, is_niri,
    wallpaper::{self, filter_images},
};
use execute::Execute;
use hyprland::shared::HyprDataActive;
use itertools::Itertools;
use niri_ipc::{Request, Response, socket::Socket};

fn pqiv_hyprland_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    let mon = hyprland::data::Monitor::get_active().expect("could not get active monitor");

    // handle vertical monitor
    let width = f64::from(mon.width.max(mon.height)) * TARGET_PERCENT;
    // target 16: 9 aspect ratio
    let height = width / 16.0 * 9.0;

    format!("[float;size {} {};center]", width.floor(), height.floor())
}

fn niri_window_title() -> String {
    // append monitor name to title so relevant window-rule can match it
    let Ok(Response::FocusedOutput(Some(curr_mon))) = Socket::connect()
        .expect("failed to connect to niri socket")
        .send(Request::FocusedOutput)
        .expect("failed to send FocusedOutput request to niri")
    else {
        panic!("Failed to get focused output from niri");
    };

    format!("wallpaper-selector-{}", curr_mon.name)
}

#[allow(clippy::module_name_repetitions)]
pub fn show_pqiv(args: &WallpaperFilterArgs) {
    let has_filters =
        args.no_faces || args.single_face || args.multiple_faces || args.faces.is_some();

    if is_hyprland() {
        let img_arg = if has_filters {
            let images = filter_images(wallpaper::dir()).collect_vec();
            filter_images_by_faces(&images, args)
                .map(|img| format!("'{img}'"))
                .join(" ")
        } else {
            wallpaper::dir()
                .to_str()
                .expect("could not convert wallpaper dir to str")
                .to_string()
        };

        // hyprland allows setting rules while spawning
        let pqiv = format!("{} pqiv --shuffle {}", pqiv_hyprland_float_rule(), img_arg);

        {
            hyprland::dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
        }
    }

    if is_niri() {
        use execute::Execute;

        // NOTE: niri uses a custom version of pqiv that forces a GDK wayland backend
        // so it doesn't resize on initial spawn via a keybind
        let mut cmd = execute::command_args!(
            "pqiv",
            "--shuffle",
            // disable fullscreen on niri as using the GDK wayland backend breaks fullscreen scaling
            "--bind-key",
            "f { nop() }",
            "--window-title",
            niri_window_title()
        );

        cmd.env("GDK_BACKEND", "wayland");

        if has_filters {
            let images = filter_images(wallpaper::dir()).collect_vec();
            cmd.args(filter_images_by_faces(&images, args))
        } else {
            cmd.arg(wallpaper::dir())
        };

        cmd.execute().expect("failed to execute pqiv");
    }
}

pub fn show_history(args: &WallpaperFilterArgs) {
    let history = wallpaper::history();
    let history = history
        .iter()
        .skip(1) // skip the current wallpaper
        .map(|(path, _)| path)
        .collect_vec();

    let has_filters =
        args.no_faces || args.single_face || args.multiple_faces || args.faces.is_some();

    let history = if has_filters {
        filter_images_by_faces(&history, args).collect_vec()
    } else {
        history
            .iter()
            .map(|p| p.display().to_string())
            .collect_vec()
    };

    if is_hyprland() {
        let history_arg = history.iter().map(|p| format!("'{p}'")).join(" ");
        let pqiv = format!("{} pqiv {}", pqiv_hyprland_float_rule(), history_arg);
        hyprland::dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
    }

    if is_niri() {
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
