use dotfiles_utils::{hypr, ActiveWindow};

fn main() {
    let activewindow = ActiveWindow::new();
    let curr_mon = activewindow.get_monitor();

    // figure out dimensions of target window with aspect ratio 16:9
    let target_w = (0.2 * curr_mon.width as f32) as i32;
    let target_h = (target_w as f32 / 16.0 * 9.0) as i32;

    hypr(&["fakefullscreen"]);
    hypr(&["togglefloating", "active"]);
    hypr(&["pin", "active"]);

    if !activewindow.floating {
        hypr(&[
            "resizeactive",
            "exact",
            &target_w.to_string(),
            &target_h.to_string(),
        ]);

        let activewindow = ActiveWindow::new();
        const PADDING: i32 = 30; // target distance from corner of screen

        let mon_bottom = curr_mon.y + curr_mon.height;
        let mon_right = curr_mon.x + curr_mon.width;

        let delta_x = mon_right - PADDING - target_w - activewindow.at.0;
        let delta_y = mon_bottom - PADDING - target_h - activewindow.at.1;

        hypr(&["moveactive", &delta_x.to_string(), &delta_y.to_string()]);
    } else {
        // reset the border
        hypr(&["fullscreen", "0"])
    }
}
