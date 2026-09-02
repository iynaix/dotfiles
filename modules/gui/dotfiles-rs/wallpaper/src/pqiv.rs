use std::process::Stdio;

use crate::{cli::WallpaperFilterArgs, filter_images_by_faces};
use common::{
    is_hyprland, is_umbriel,
    wallpaper::{self, filter_images},
};
use execute::Execute;
use hyprland::shared::HyprDataActive;
use itertools::Itertools;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UmbrielWorkspace {
    pub active: bool,
    pub focused: bool,
    pub id: String,
    pub index: i64,
    pub layout: String,
    pub name: String,
    pub output: String,
}

fn pqiv_hyprland_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    let mon = hyprland::data::Monitor::get_active().expect("could not get active monitor");

    // handle vertical monitor
    let width = f64::from(mon.width.max(mon.height)) * TARGET_PERCENT;
    // target 16: 9 aspect ratio
    let height = width / 16.0 * 9.0;

    format!(
        r#"{{ float = true, center = true, size = "{} {}" }}"#,
        width.floor(),
        height.floor()
    )
}

fn umbriel_window_title() -> String {
    let umbriel_cmd = execute::command_args!("umbriel", "workspaces", "--json")
        .stdout(Stdio::piped())
        .execute_output()
        .expect("failed to run umbriel workspaces");
    let umbriel_json =
        String::from_utf8(umbriel_cmd.stdout).expect("invalid utf8 from umbriel workspaces");
    let wksps: Vec<UmbrielWorkspace> =
        serde_json::from_str(&umbriel_json).expect("failed to parse json");

    for w in &wksps {
        if w.focused {
            return format!("wallpaper-selector-{}", w.output);
        }
    }

    String::new()
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
        let lua_dispatch = format!(
            r#"hl.dsp.exec_cmd("pqiv --shuffle {img_arg}", {})"#,
            pqiv_hyprland_float_rule()
        );

        execute::command_args!("hyprctl", "dispatch", lua_dispatch)
            .execute()
            .expect("failed to execute pqiv");
    }

    if is_umbriel() {
        // NOTE: niri uses a custom version of pqiv that forces a GDK wayland backend
        // so it doesn't resize on initial spawn via a keybind
        let mut cmd = execute::command_args!(
            "pqiv",
            "--shuffle",
            // disable fullscreen on niri as using the GDK wayland backend breaks fullscreen scaling
            "--bind-key",
            "f { nop() }",
            "--window-title",
            umbriel_window_title()
        );

        // cmd.env("GDK_BACKEND", "wayland");

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

        // hyprland allows setting rules while spawning
        let lua_dispatch = format!(
            r#"hl.dsp.exec_cmd("pqiv {}", {})"#,
            history_arg,
            pqiv_hyprland_float_rule()
        );

        execute::command_args!("hyprctl", "dispatch", lua_dispatch)
            .execute()
            .expect("failed to execute pqiv");
    }

    if is_umbriel() {
        execute::command_args!(
            "pqiv",
            // disable fullscreen on niri as using the GDK wayland backend breaks fullscreen scaling
            "--bind-key",
            "f { nop() }",
            "--window-title",
            umbriel_window_title()
        )
        .args(history)
        .execute()
        .expect("failed to execute pqiv");
    }
}
