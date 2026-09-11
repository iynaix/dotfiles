use crate::{cli::WallpaperFilterArgs, filter_images_by_faces};
use common::{
    is_hyprland, is_umbriel,
    umbriel::UmbrielMonitor,
    wallpaper::{self, filter_images},
};
use execute::Execute;
use hyprland::shared::HyprDataActive;
use itertools::Itertools;

fn target_window_size() -> Option<(u32, u32)> {
    const TARGET_PERCENT: f64 = 0.3;
    let mut width = 0.0;

    if is_hyprland() {
        let mon = hyprland::data::Monitor::get_active().expect("could not get active monitor");

        // handle vertical monitor
        width = f64::from(mon.width.max(mon.height)) * TARGET_PERCENT;
    }

    if is_umbriel() {
        if let Some(mode) = UmbrielMonitor::focused()
            .as_ref()
            .and_then(|mon| mon.current_mode())
        {
            width = f64::from(mode.width) * TARGET_PERCENT;
        }
    }

    if width == 0.0 {
        return None;
    }

    // target 16: 9 aspect ratio
    let height = width / 16.0 * 9.0;
    return Some((width as u32, height as u32));
}

#[allow(clippy::module_name_repetitions)]
pub fn show_swayimg(args: &WallpaperFilterArgs) {
    let has_filters =
        args.no_faces || args.single_face || args.multiple_faces || args.faces.is_some();

    let mut cmd = execute::command_args!(
        "swayimg",
        "--appid",
        "wallpaper-selector",
        "--execute",
        "swayimg.imagelist.order = \"random\""
    );

    if let Some((w, h)) = target_window_size() {
        cmd.arg("--size").arg(format!("{w},{h}"));
    }

    if has_filters {
        let images = filter_images(wallpaper::dir()).collect_vec();
        cmd.args(filter_images_by_faces(&images, args))
    } else {
        cmd.arg(wallpaper::dir())
    };

    cmd.execute().expect("failed to execute swayimg");
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

    let mut cmd = execute::command_args!(
        "swayimg",
        "--appid",
        "wallpaper-selector",
        // show images in the given order
        "--execute",
        "swayimg.imagelist.order = \"none\""
    );

    if let Some((w, h)) = target_window_size() {
        cmd.arg("--size").arg(format!("{w},{h}"));
    }

    cmd.args(history).execute().expect("failed to execute pqiv");
}
