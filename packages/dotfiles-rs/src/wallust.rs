use crate::{
    full_path, json, kill_wrapped_process,
    nixinfo::{hyprland_colors, NixInfo},
    vertical_dimensions,
    wallpaper::WallInfo,
    CommandUtf8,
};
use execute::Execute;
use hyprland::{data::Monitors, keyword::Keyword, shared::HyprData};
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

/// returns the area of a triangle formed by the given RGB tuples
fn color_triangle_area(a: &Rgb, b: &Rgb, c: &Rgb) -> i64 {
    let (x1, y1, z1) = a;
    let (x2, y2, z2) = b;
    let (x3, y3, z3) = c;

    let t1 = i64::from((y2 - y1) * (z3 - z1) - (z2 - z1) * (y3 - y1));
    let t2 = i64::from((z2 - z1) * (x3 - x1) - (x2 - x1) * (z3 - z1));
    let t3 = i64::from((x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1));

    // should be square root then halved, but makes no difference if just comparing
    t1 * t1 + t2 * t2 + t3 * t3
}

/// sort wallust colors by how contrasting they are to the background and foreground,
/// using the area of a triangle formed by the colors
fn accents_by_contrast() -> Vec<String> {
    let nixinfo = NixInfo::after();
    let mut colors: Vec<_> = nixinfo
        .colors
        .into_iter()
        .filter_map(|(name, color)| {
            // ignore black and white
            if matches!(name.as_str(), "color0" | "color7" | "color8" | "color15") {
                return None;
            }
            Some(color)
        })
        .collect();

    colors.sort_by_key(|color| {
        // get the area of the triangle formed by the colors
        color_triangle_area(
            &hex_to_rgb(&nixinfo.special.background),
            &hex_to_rgb(&nixinfo.special.foreground),
            &hex_to_rgb(color),
        )
    });
    colors.reverse();

    colors
}

fn accent_or_default(accents: &[String], accent_idx: usize, default: &str) -> String {
    accents.get(accent_idx).map_or_else(
        || default.to_string(),
        |accent| format!("{})", accent.replace('#', "rgb(")),
    )
}

fn apply_hyprland_colors(accents: &[String], hyprland_colors: &[String]) {
    // update borders
    Keyword::set(
        "general:col.active_border",
        format!(
            "{} {} 45deg",
            accent_or_default(accents, 0, &hyprland_colors[4]),
            &hyprland_colors[0],
        ),
    )
    .expect("failed to set hyprland active border color");

    Keyword::set("general:col.inactive_border", hyprland_colors[0].clone())
        .expect("failed to set hyprland inactive border color");

    // pink border for monocle windows
    Keyword::set(
        "windowrulev2",
        format!(
            "bordercolor {},fullscreen:1",
            accent_or_default(accents, 1, &hyprland_colors[5]),
        ),
    )
    .expect("failed to set hyprland fakefullscreen border color");

    // teal border for floating windows
    Keyword::set(
        "windowrulev2",
        format!(
            "bordercolor {},floating:1",
            accent_or_default(accents, 2, &hyprland_colors[6]),
        ),
    )
    .expect("failed to set hyprland floating border color");

    // yellow border for sticky (must be floating) windows
    Keyword::set(
        "windowrulev2",
        format!(
            "bordercolor {},pinned:1",
            accent_or_default(accents, 3, &hyprland_colors[3])
        ),
    )
    .expect("failed to set hyprland sticky border color");
}

/// applies the wallust colors to various applications
pub fn apply_colors() {
    let has_nix_json = full_path("~/.cache/wallust/nix.json").exists();
    let hyprland_colors = if has_nix_json {
        hyprland_colors(&NixInfo::after().colors)
    } else {
        #[derive(serde::Deserialize)]
        struct Colorscheme {
            colors: HashMap<String, String>,
        }

        let cs_path = full_path("~/.config/wallust/themes/catppuccin-mocha.json");
        let cs: Colorscheme = json::load(&cs_path).unwrap_or_else(|_| {
            panic!("unable to read colorscheme at {:?}", &cs_path);
        });

        hyprland_colors(&cs.colors)
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

    // sleep to prevent waybar race condition
    std::thread::sleep(std::time::Duration::from_secs(1));

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

    crop_lockscreens(wallpaper_info, wallpaper);
}

/// crops the wallpapers for usage with the lockscreens
fn crop_lockscreens(wallpaper_info: &Option<WallInfo>, wallpaper: &str) {
    // replace image path in hyprlock config at ~/.config/hypr/hyprlock.conf
    let hyprlock_conf = full_path("~/.config/hypr/hyprlock.conf");
    if !hyprlock_conf.exists() {
        return;
    }
    let mut contents =
        std::fs::read_to_string(&hyprlock_conf).expect("Could not read hyprlock.conf");
    let nix_info = NixInfo::before();

    if let Some(info) = wallpaper_info {
        let monitors = Monitors::get().expect("could not get monitors");
        let monitors = monitors
            .iter()
            // monitor should be present in nix.json
            .filter(|mon| {
                nix_info
                    .monitors
                    .iter()
                    .any(|nix_mon| nix_mon.name == mon.name)
            })
            // filter monitors with geometry info
            .filter_map(|mon| {
                let (mon_width, mon_height) = vertical_dimensions(mon);
                info.get_geometry_str(mon_width, mon_height).map(|_| mon)
            });

        for mon in monitors {
            let wall_re = regex::Regex::new(&format!(r"{}\s+# {}", &wallpaper, mon.name))
                .expect("invalid hyprlock path regex");
            contents = wall_re
                // use the file created by swww for cropping
                .replace(&contents, format!("/tmp/swww__{}.webp", mon.name))
                .to_string();
        }

        std::fs::write(&hyprlock_conf, contents).expect("Could not write hyprlock.conf");
    }
}

type Rgb = (i32, i32, i32);

/// hex string to f64 RGB tuple
fn hex_to_rgb(hex: &str) -> Rgb {
    let hex = hex.trim_start_matches('#');

    let r = i32::from_str_radix(&hex[0..2], 16).unwrap_or_else(|_| {
        panic!("invalid hex color: {hex}");
    });
    let g = i32::from_str_radix(&hex[2..4], 16).unwrap_or_else(|_| {
        panic!("invalid hex color: {hex}");
    });
    let b = i32::from_str_radix(&hex[4..6], 16).unwrap_or_else(|_| {
        panic!("invalid hex color: {hex}");
    });

    (r, g, b)
}

// euclidean distance squared between colos, no sqrt necessary since we're only comparing
pub fn distance_sq(a: &Rgb, b: &Rgb) -> i32 {
    let (r1, g1, b1) = a;
    let (r2, g2, b2) = b;

    let dr = r1 - r2;
    let dg = g1 - g2;
    let db = b1 - b2;

    db * db + dg * dg + dr * dr
}

pub fn set_gtk_and_icon_theme() {
    let nixinfo = NixInfo::after();

    let theme_accents: HashMap<_, _> = nixinfo
        .theme_accents
        .iter()
        .map(|(k, v)| (k, hex_to_rgb(v)))
        .collect();

    let wallust_colors: Vec<_> = nixinfo
        .colors
        .iter()
        .filter_map(|(name, color)| {
            // ignore black
            if name == "color0" || name == "color7" {
                return None;
            }

            Some(hex_to_rgb(color))
        })
        .collect();

    let mut variant = String::new();
    let mut min_distance = i32::MAX;

    for (accent_name, accent_color) in theme_accents {
        for wallust_color in &wallust_colors {
            let distance = distance_sq(&accent_color, wallust_color);
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

pub fn set_waybar_accent(accent: &str) {
    let nixinfo = NixInfo::after();

    // get inverse color for inversed module classes
    let inverse = hex_to_rgb(accent);
    let inverse = format!(
        "#{:02X}{:02X}{:02X}",
        255 - inverse.0,
        255 - inverse.1,
        255 - inverse.2
    );

    let css_path = full_path("~/.config/waybar/style.css");
    let mut css = std::fs::read_to_string(&css_path).expect("could not read waybar css");

    // replace old foreground color with new color
    css = css.replace(&nixinfo.special.foreground, accent);

    // replace inverse classes
    css = css
        .lines()
        .map(|line| {
            if line.ends_with("/* inverse */") {
                format!("color: {inverse}; /* inverse */")
            } else {
                line.to_string()
            }
        })
        .collect::<Vec<String>>()
        .join("\n");

    std::fs::write(css_path, css).expect("could not write waybar css");
}
