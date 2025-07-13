use common::wallpaper;
use itertools::Itertools;

#[allow(dead_code)]
fn pqiv_hyprland_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    use hyprland::shared::HyprDataActive;
    let mon = hyprland::data::Monitor::get_active().expect("could not get active monitor");

    let mut width = f64::from(mon.width) * TARGET_PERCENT;
    let mut height = f64::from(mon.height) * TARGET_PERCENT;

    // handle vertical monitor
    if height > width {
        std::mem::swap(&mut width, &mut height);
    }

    format!("[float;size {} {};center]", width.floor(), height.floor())
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

        execute::command_args!("pqiv", "--shuffle", "--window-title", "wallpaper-rofi")
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

        execute::command_args!("pqiv", "--window-title", "wallpaper-rofi")
            .args(history)
            .execute()
            .expect("failed to execute pqiv");
    }
}
