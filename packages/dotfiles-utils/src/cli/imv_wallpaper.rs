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

    if cfg!(feature = "hyprland") {
        let float_rule = format!("[float;size {} {};center]", width as i32, height as i32);

        // bind esc to behave like rofi
        let esc_bind = "bind <Escape> quit";

        hypr([
            "exec",
            &format!(
                "{float_rule} imv -c '{esc_bind}' {}",
                &wallpaper::randomize_wallpapers()
            ),
        ]);
    }
}
