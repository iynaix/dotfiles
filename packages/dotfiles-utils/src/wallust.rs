use crate::{
    execute_wrapped_process, filename, full_path, json,
    monitor::Monitor,
    nixinfo::{hyprland_colors, NixInfo},
    wallpaper::WallInfo,
    CommandUtf8,
};
use execute::Execute;
use std::{collections::HashMap, path::PathBuf};

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

    if cfg!(feature = "hyprland") {
        // update borders
        execute::command_args!(
            "hyprctl",
            "keyword",
            "general:col.active_border",
            &format!("{} {} 45deg", hyprland_colors[4], hyprland_colors[0]),
        )
        .execute()
        .expect("failed to set hyprland active border color");

        execute::command_args!(
            "hyprctl",
            "keyword",
            "general:col.inactive_border",
            &hyprland_colors[0]
        )
        .execute()
        .expect("failed to set hyprland inactive border color");

        // pink border for monocle windows
        execute::command_args!(
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},fullscreen:1", &hyprland_colors[5]),
        )
        .execute()
        .expect("failed to set hyprland border color");
        // teal border for floating windows
        execute::command_args!(
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},floating:1", &hyprland_colors[6]),
        )
        .execute()
        .expect("failed to set hyprland floating border color");
        // yellow border for sticky (must be floating) windows
        execute::command_args!(
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},pinned:1", &hyprland_colors[3]),
        )
        .execute()
        .expect("failed to set hyprland sticky border color");
    }

    // refresh zathura
    refresh_zathura();

    // refresh cava
    execute_wrapped_process("cava", |process| {
        execute::command_args!("killall", "-SIGUSR2", process)
            .execute()
            .ok();
    });

    // refresh wfetch
    execute_wrapped_process("wfetch", |process| {
        execute::command_args!("killall", "-SIGUSR2", process)
            .execute()
            .ok();
    });

    if cfg!(feature = "hyprland") {
        // sleep to prevent waybar race condition
        std::thread::sleep(std::time::Duration::from_secs(1));

        // refresh waybar
        execute_wrapped_process("waybar", |process| {
            execute::command_args!("killall", "-SIGUSR2", process)
                .execute()
                .ok();
        });
    }

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

    // crop wallpaper for lockscreen
    let nix_info = NixInfo::before();
    if matches!(nix_info.host.as_str(), "framework" | "xps") {
        if let Some(info) = wallpaper_info {
            if let Some(m) = Monitor::monitors().iter().find(|m| {
                nix_info
                    .monitors
                    .iter()
                    .any(|nix_mon| nix_mon.name == m.name)
            }) {
                if let Some(geometry) = info.get_geometry(m.width, m.height) {
                    // output cropped and resized wallpaper to /tmp
                    let output_fname = filename(full_path(wallpaper));
                    let output_path = PathBuf::from("/tmp").join(output_fname);
                    let output_path = output_path
                        .to_str()
                        .unwrap_or_else(|| panic!("invalid wallpaper: {output_path:?}"));

                    execute::command("convert")
                        .arg(wallpaper)
                        .arg("-crop")
                        .arg(geometry)
                        .arg("-resize")
                        .arg(&format!("{}x{}", m.width, m.height))
                        .arg(output_path)
                        .execute()
                        .expect("failed to crop wallpaper for lockscreen");

                    // replace image path in hyprlock config at ~/.config/hypr/hyprlock.conf
                    let hyprlock_conf = full_path("~/.config/hypr/hyprlock.conf");

                    if hyprlock_conf.exists() {
                        let contents = std::fs::read_to_string(&hyprlock_conf)
                            .expect("Could not read hyprlock.conf");
                        let wall_re =
                            regex::Regex::new(r"path = (.*)").expect("invalid hyprlock path regex");
                        // only replaces the first occurrence
                        let new_contents =
                            wall_re.replace(&contents, &format!("path = {output_path}"));

                        std::fs::write(&hyprlock_conf, new_contents.as_ref())
                            .expect("Could not write hyprlock.conf");
                    }
                }
            }
        }
    };
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
            if name == "color0" {
                return None;
            }

            Some(hex_to_rgb(color))
        })
        .collect();

    let mut variant = String::new();
    let mut min_distance = i32::MAX;

    for (accent_name, accent_color) in theme_accents {
        for wallust_color in &wallust_colors {
            // calculate distance between colos, no sqrt necessary since we're only comparing
            let (r1, g1, b1) = accent_color;
            let (r2, g2, b2) = wallust_color;

            let dr = r1 - r2;
            let dg = g1 - g2;
            let db = b1 - b2;

            let distance = db * db + dg * dg + dr * dr;

            if distance < min_distance {
                variant = accent_name.to_string();
                min_distance = distance;
            }
        }
    }

    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/gtk-theme")
        // requires the quotes to be GVariant compatible for dconf
        .arg(format!("'Catppuccin-Mocha-Compact-{variant}-Dark'"))
        .execute()
        .expect("failed to apply gtk theme");

    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/icon-theme")
        // requires the quotes to be GVariant compatible for dconf
        .arg(format!("'Tela-{variant}-dark'"))
        .execute()
        .expect("failed to apply icon theme");
}
