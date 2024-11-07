use common::wallpaper;
use hyprland::dispatch;
use hyprland::{
    data::Monitor,
    dispatch::{Dispatch, DispatchType},
    shared::HyprDataActive,
};
use itertools::Itertools;

fn pqiv_float_rule() -> String {
    const TARGET_PERCENT: f64 = 0.3;

    let mon = Monitor::get_active().expect("could not get active monitor");

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
    let pqiv = format!(
        "{} pqiv --shuffle '{}'",
        pqiv_float_rule(),
        &wallpaper::dir().to_str().expect("invalid wallpaper dir")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}

pub fn show_history() {
    let history = wallpaper::history();
    let history = history
        .iter()
        .skip(1) // skip the current wallpaper
        .map(|(path, _)| path)
        .collect_vec();

    let pqiv = format!(
        "{} pqiv {}",
        pqiv_float_rule(),
        history
            .iter()
            .map(|p| format!("'{}'", p.display()))
            .collect_vec()
            .join(" ")
    );

    dispatch!(Exec, &pqiv).expect("failed to execute pqiv");
}
