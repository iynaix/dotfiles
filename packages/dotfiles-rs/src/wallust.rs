use crate::{
    colors::{NixColors, Rgb},
    full_path, json, kill_wrapped_process,
    wallpaper::WallInfo,
    CommandUtf8,
};
use core::panic;
use execute::Execute;
use hyprland::keyword::Keyword;
use std::collections::HashMap;

pub const CUSTOM_THEMES: [&str; 6] = [
    "catppuccin-frappe",
    "catppuccin-macchiato",
    "catppuccin-mocha",
    "decay-dark",
    "night-owl",
    "tokyo-night",
];

pub fn apply_theme(theme: &str) {
    if CUSTOM_THEMES.contains(&theme) {
        let colorscheme_file = full_path(format!("~/.config/wallust/themes/{theme}.json"));
        execute::command_args!(
            "wallust",
            "cs",
            colorscheme_file
                .to_str()
                .unwrap_or_else(|| panic!("invalid colorscheme file: {colorscheme_file:?}")),
        )
        .execute()
        .unwrap_or_else(|_| panic!("failed to apply colorscheme {theme}"));
    } else {
        execute::command_args!("wallust", "theme", &theme)
            .execute()
            .unwrap_or_else(|_| panic!("failed to apply wallust theme {theme}"));
    }
}

fn refresh_zathura() {
    if let Some(zathura_pid_raw) = execute::command_args!(
        "dbus-send",
        "--print-reply",
        "--dest=org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus.ListNames",
    )
    .execute_stdout_lines()
    .iter()
    .find(|line| line.contains("org.pwmt.zathura"))
    {
        let zathura_pid = zathura_pid_raw
            .split('"')
            .max_by_key(|s| s.len())
            .expect("could not extract zathura pid");

        // send message to zathura via dbus
        execute::command_args!(
            "dbus-send",
            "--type=method_call",
            &format!("--dest={zathura_pid}"),
            "/org/pwmt/zathura",
            "org.pwmt.zathura.ExecuteCommand",
            "string:source",
        )
        .execute()
        .ok();
    }
}

/// sort wallust colors by how contrasting they are to the background and foreground
fn accents_by_contrast() -> Vec<Rgb> {
    let nixinfo = NixColors::new();
    // ignore black and white
    let mut colors: Vec<_> = nixinfo
        .filter_colors(&["color0", "color7", "color8", "color15"])
        .into_values()
        .collect();

    let (x1, y1, z1) = nixinfo.special.background.to_i64();
    let (x2, y2, z2) = nixinfo.special.foreground.to_i64();

    colors.sort_by_key(|c| {
        let (x3, y3, z3) = c.to_i64();

        // compute area of the triangle formed by the colors
        let t1 = (y2 - y1) * (z3 - z1) - (z2 - z1) * (y3 - y1);
        let t2 = (z2 - z1) * (x3 - x1) - (x2 - x1) * (z3 - z1);
        let t3 = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1);

        // should be square root then halved, but makes no difference if just comparing
        // negative for sorting in descending order
        -(t1 * t1 + t2 * t2 + t3 * t3)
    });

    colors
}

fn apply_hyprland_colors(accents: &[Rgb], colors: &HashMap<String, Rgb>) {
    let color = |idx: usize| {
        colors
            .get(&format!("color{idx}"))
            .unwrap_or_else(|| panic!("key color{idx} not found"))
    };
    let accent_or_color = |accent_idx: usize, color_idx: usize| {
        accents
            .get(accent_idx)
            .unwrap_or_else(|| color(color_idx))
            .to_rgb_str()
    };

    // update borders
    Keyword::set(
        "general:col.active_border",
        format!("{} {} 45deg", accent_or_color(0, 4), &color(0).to_rgb_str(),),
    )
    .expect("failed to set hyprland active border color");

    Keyword::set("general:col.inactive_border", color(0).to_rgb_str())
        .expect("failed to set hyprland inactive border color");

    // pink border for monocle windows
    Keyword::set(
        "windowrulev2",
        format!("bordercolor {},fullscreen:1", accent_or_color(1, 5),),
    )
    .expect("failed to set hyprland fakefullscreen border color");

    // teal border for floating windows
    Keyword::set(
        "windowrulev2",
        format!("bordercolor {},floating:1", accent_or_color(2, 6)),
    )
    .expect("failed to set hyprland floating border color");

    // yellow border for sticky (must be floating) windows
    Keyword::set(
        "windowrulev2",
        format!("bordercolor {},pinned:1", color(3).to_rgb_str()),
    )
    .expect("failed to set hyprland sticky border color");
}

/// applies the wallust colors to various applications
pub fn apply_colors() {
    let has_nix_json = full_path("~/.cache/wallust/nix.json").exists();
    let hyprland_colors = if has_nix_json {
        NixColors::new().colors
    } else {
        #[derive(serde::Deserialize)]
        struct Colorscheme {
            colors: HashMap<String, Rgb>,
        }

        let cs_path = full_path("~/.config/wallust/themes/catppuccin-mocha.json");
        let cs: Colorscheme = json::load(&cs_path).unwrap_or_else(|_| {
            panic!("unable to read colorscheme at {:?}", &cs_path);
        });

        cs.colors
    };

    let accents = if has_nix_json {
        accents_by_contrast()
    } else {
        Vec::new()
    };

    apply_hyprland_colors(&accents, &hyprland_colors);

    refresh_zathura();

    // refresh cava
    kill_wrapped_process("cava", "SIGUSR2");

    // refresh wfetch
    kill_wrapped_process("wfetch", "SIGUSR2");

    // set the waybar accent color to have more contrast
    if let Some(accent) = accents.first() {
        set_waybar_accent(accent);
    }

    // refresh waybar
    kill_wrapped_process("waybar", "SIGUSR2");

    // set gtk theme
    if has_nix_json {
        set_gtk_and_icon_theme();
    }
}

/// runs wallust with options from wallpapers.csv
pub fn from_wallpaper(wallpaper_info: &Option<WallInfo>, wallpaper: &str) {
    let mut wallust = execute::command_args!("wallust", "run", "--no-cache", "--check-contrast");

    // normalize the options for wallust
    if let Some(WallInfo { wallust: opts, .. }) = wallpaper_info {
        // split opts into flags
        if !opts.is_empty() {
            let opts: Vec<&str> = opts.split(' ').map(str::trim).collect();
            wallust.args(opts);
        }
    }

    wallust
        .arg(wallpaper)
        .execute()
        .expect("wallust: failed to set colors from wallpaper");
}

pub fn set_gtk_and_icon_theme() {
    let nixinfo = NixColors::new();

    // ignore black
    let wallust_colors: Vec<_> = nixinfo
        .filter_colors(&["color0", "color7"])
        .into_values()
        .collect();

    let mut variant = String::new();
    let mut min_distance = i64::MAX;

    for (accent_name, accent_color) in nixinfo.theme_accents {
        for wallust_color in &wallust_colors {
            let distance = accent_color.distance_sq(wallust_color);
            if distance < min_distance {
                variant = accent_name.to_string();
                min_distance = distance;
            }
        }
    }

    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/gtk-theme")
        // requires the quotes to be GVariant compatible for dconf
        .arg(format!("'catppuccin-mocha-{variant}-compact'"))
        .execute()
        .expect("failed to apply gtk theme");

    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/icon-theme")
        // requires the quotes to be GVariant compatible for dconf
        .arg(format!("'Tela-{variant}-dark'"))
        .execute()
        .expect("failed to apply icon theme");
}

pub fn set_waybar_accent(accent: &Rgb) {
    let nixinfo = NixColors::new();

    // get inverse color for inversed module classes
    let inverse = accent.inverse();

    let css_path = full_path("~/.config/waybar/style.css");
    let mut css = std::fs::read_to_string(&css_path).expect("could not read waybar css");

    // replace old foreground color with new inverse color
    css = css.replace(
        &nixinfo.special.foreground.to_hex_str(),
        &accent.to_hex_str(),
    );

    // replace inverse classes
    css = css
        .lines()
        .map(|line| {
            if line.ends_with("/* inverse */") {
                format!("color: {}; /* inverse */", inverse.to_hex_str())
            } else {
                line.to_string()
            }
        })
        .collect::<Vec<String>>()
        .join("\n");

    std::fs::write(css_path, css).expect("could not write waybar css");
}
