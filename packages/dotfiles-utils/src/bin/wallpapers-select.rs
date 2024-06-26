use dotfiles_utils::{hypr, monitor::Monitor, wallpaper};

#[allow(clippy::cast_possible_truncation, clippy::cast_precision_loss)]
fn main() {
    const TARGET_PERCENT: f32 = 0.3;

    let mon = Monitor::focused();

    let mut width = mon.width as f32 * TARGET_PERCENT;
    let mut height = mon.height as f32 * TARGET_PERCENT;

    // handle vertical monitor
    if height > width {
        std::mem::swap(&mut width, &mut height);
    }

    let float_rule = format!("[float;size {} {};center]", width as i32, height as i32);

    hypr([
        "exec",
        &format!(
            "{float_rule} pqiv --shuffle '{}'",
            &wallpaper::dir().to_str().expect("invalid wallpaper dir")
        ),
    ]);
}
