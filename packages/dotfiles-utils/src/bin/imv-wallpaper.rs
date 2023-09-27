use dotfiles_utils::{hypr, wallpaper, Monitor};
use rand::Rng;

fn main() {
    const TARGET_PERCENT: f32 = 0.3;

    let mon = Monitor::focused();

    let mut width = mon.width * TARGET_PERCENT;
    let mut height = mon.height * TARGET_PERCENT;

    // handle vertical monitor
    if height > width {
        std::mem::swap(&mut width, &mut height);
    }

    let float_rule = format!("[float;size {} {};center]", width as i32, height as i32);

    // to behave like rofi
    let esc_bind = "bind <Escape> quit";
    let rand_idx = rand::thread_rng().gen_range(1..=wallpaper::all().len());

    hypr(&[
        "exec",
        &format!(
            "{float_rule} imv -n {rand_idx} -c '{esc_bind}' {}",
            wallpaper::dir()
        ),
    ]);
}
