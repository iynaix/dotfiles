use crate::{
    CommandUtf8,
    colors::{NixColors, Rgb},
    full_path, json, kill_wrapped_process,
    wallpaper::WallInfo,
};
use core::panic;
use execute::Execute;
use image::ImageReader;
use itertools::Itertools;
use regex::Regex;
use std::{collections::HashMap, path::Path};

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
    if let Some(zathura_pid) = execute::command_args!(
        "dbus-send",
        "--print-reply",
        "--dest=org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus.ListNames",
    )
    .execute_stdout_lines()
    .unwrap_or_default()
    .iter()
    .find(|line| line.contains("org.pwmt.zathura"))
    .and_then(|zathura_pid_raw| zathura_pid_raw.split('"').max_by_key(|s| s.len()))
    {
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

// replacements is a Vec of (regex, replacement) tuples
fn replace_in_file<P>(path: P, replacements: Vec<(&str, &str)>)
where
    P: AsRef<Path> + std::fmt::Debug,
{
    let path = path.as_ref();

    if let Ok(mut content) = std::fs::read_to_string(path) {
        for (regexp, replacement) in replacements {
            let re = Regex::new(regexp).expect("invalid regex");

            content = re.replace_all(&content, replacement).into_owned();
        }

        // handle case where it is a symlink to nix store, replace with writable file
        if path.is_symlink() {
            std::fs::remove_file(path)
                .unwrap_or_else(|_| panic!("unable to remove the {path:?} symlink"));
        }

        std::fs::write(path, content).unwrap_or_else(|_| panic!("could not write {path:?}"));
    } else {
        panic!("unable to read {path:?}");
    }
}

#[cfg(feature = "hyprland")]
fn apply_hyprland_colors(accents: &[Rgb], colors: &HashMap<String, Rgb>) {
    use hyprland::keyword::Keyword;

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
        "windowrule",
        format!("bordercolor {},fullscreen:1", accent_or_color(1, 5),),
    )
    .expect("failed to set hyprland fakefullscreen border color");

    // teal border for floating windows
    Keyword::set(
        "windowrule",
        format!("bordercolor {},floating:1", accent_or_color(2, 6)),
    )
    .expect("failed to set hyprland floating border color");

    // yellow border for sticky (must be floating) windows
    Keyword::set(
        "windowrule",
        format!("bordercolor {},pinned:1", color(3).to_rgb_str()),
    )
    .expect("failed to set hyprland sticky border color");
}

#[cfg(feature = "niri")]
fn apply_niri_colors(accents: &[Rgb], colors: &HashMap<String, Rgb>) {
    use crate::nixjson::NixJson;
    let config_path = full_path("~/.config/niri/config.kdl");

    // replace symlink to nix store if needed
    // it will replaced by the default config on startup as impermanence will remove the writable file anyway
    if config_path.is_symlink() {
        let contents = std::fs::read(&config_path).expect("unable to read niri config.kdl");
        std::fs::remove_file(&config_path).expect("unable to remove niri config.kdl symlink");
        std::fs::write(&config_path, contents).expect("unable to write niri config.kdl");
    }

    let color = |idx: usize| {
        colors
            .get(&format!("color{idx}"))
            .unwrap_or_else(|| panic!("key color{idx} not found"))
    };
    let accent_or_color = |accent_idx: usize, color_idx: usize| {
        accents
            .get(accent_idx)
            .unwrap_or_else(|| color(color_idx))
            .to_hex_str()
    };

    let active = format!(
        r#"active-gradient angle=45 from="{}" relative-to="workspace-view" to="{}""#,
        accent_or_color(0, 4),
        accent_or_color(1, 0),
    );
    let inactive = format!(r#"inactive-color "{}""#, &color(0).to_hex_str());

    let mut replacements = vec![
        // focus-ring colors
        (r"active-gradient .*", active.as_str()),
        (r"inactive-color .*", inactive.as_str()),
        // increase maximum shadow spread value to workaround config validation errors during nix build
        ("spread 1024", "spread 2048"),
    ];

    // add blur settings if enabled, has to be done here as niri-flake cannot be extended :(
    if Some(true) == NixJson::new().niri_blur
        && let Ok(content) = std::fs::read_to_string(&config_path)
    {
        // add the blur settings if they're not already there
        if !content.contains("blur {") {
            replacements.push((
                "always-center-single-column",
                r"
    always-center-single-column

    blur {
        on
        passes 3
        radius 2.0
    }
    ",
            ));
        }
    }

    replace_in_file(&config_path, replacements);
}

/// sort accents by their color usage within the wallpaper
fn accents_by_usage(wallpaper: &str, accents: &[Rgb]) -> HashMap<Rgb, usize> {
    // open wallpaper and read colors
    let img = ImageReader::open(wallpaper)
        .expect("could not open image")
        .decode()
        .expect("could not decode image")
        .to_rgb8();

    // initialize with each accent as a color might not be used
    let mut color_counts: HashMap<_, _> = accents.iter().map(|a| (a.clone(), 0)).collect();

    // sample middle of every 9x9 pixel block
    for x in (4..img.width()).step_by(5) {
        for y in (4..img.height()).step_by(5) {
            let px = img.get_pixel(x, y);

            let closest_color = accents
                .iter()
                .enumerate()
                .min_by_key(|(_, color)| {
                    color.distance_sq(&Rgb {
                        r: px[0],
                        g: px[1],
                        b: px[2],
                    })
                })
                .expect("could not find closest color");

            // store the closest color
            *color_counts.entry(closest_color.1.clone()).or_default() += 1;
        }
    }

    color_counts
        .iter()
        .sorted_by(|a, b| b.1.cmp(a.1))
        .enumerate()
        .map(|(n, (color, _count))| (color.clone(), n))
        .collect()
}

/// sort accents by how contrasting they are to the background and foreground
fn accents_by_contrast(accents: &[Rgb]) -> HashMap<Rgb, usize> {
    let nixcolors = NixColors::new().expect("unable to parse nix.json");

    // sort by contrast to background
    accents
        .iter()
        .sorted_by(|c1, c2| {
            let contrast1 = c1.contrast_ratio(&nixcolors.special.background);
            let contrast2 = c2.contrast_ratio(&nixcolors.special.background);

            contrast2
                .partial_cmp(&contrast1)
                .unwrap_or(std::cmp::Ordering::Equal)
        })
        .enumerate()
        .map(|(n, color)| (color.clone(), n))
        .collect()
}

/// applies the wallust colors to various applications
pub fn apply_colors() {
    if let Ok(nixcolors) = NixColors::new() {
        // ignore black and white
        let colors = nixcolors
            .filter_colors(&["color0", "color7", "color8", "color15"])
            .into_values()
            .collect_vec();

        let by_usage = accents_by_usage(&nixcolors.wallpaper, &colors);

        let by_contrast = accents_by_contrast(&colors);

        let accents = by_contrast
            .iter()
            // calculate score for each color
            .map(|(color, i)| {
                // how much of the score should be based on contrast
                let contrast_pct = 0.78;

                (
                    (*i as f64).mul_add(
                        contrast_pct,
                        (by_usage[color] as f64) * (1.0 - contrast_pct),
                    ),
                    color.clone(),
                )
            })
            .sorted_by(|a, b| a.0.partial_cmp(&b.0).expect("could not compare floats"))
            .map(|(_, color)| color)
            .collect_vec();

        #[cfg(feature = "hyprland")]
        apply_hyprland_colors(&accents, &nixcolors.colors);

        #[cfg(feature = "niri")]
        apply_niri_colors(&accents, &nixcolors.colors);

        // set the waybar accent color to have more contrast
        set_waybar_colors(&accents[0]);

        set_gtk_and_icon_theme(&nixcolors, &accents[0]);
    } else {
        #[derive(serde::Deserialize)]
        struct Colorscheme {
            colors: HashMap<String, Rgb>,
        }

        let cs_path = full_path("~/.config/wallust/themes/catppuccin-mocha.json");
        let cs: Colorscheme = json::load(&cs_path).unwrap_or_else(|_| {
            panic!("unable to read colorscheme at {:?}", &cs_path);
        });

        #[cfg(feature = "hyprland")]
        apply_hyprland_colors(&[], &cs.colors);

        #[cfg(feature = "niri")]
        apply_niri_colors(&[], &cs.colors);
    }

    refresh_zathura();

    // refresh cava
    kill_wrapped_process("cava", "SIGUSR2");

    // refresh wfetch
    kill_wrapped_process("wfetch", "SIGUSR2");

    // refresh waybar, process is killed and restarted as sometimes reloading kills the process :(
    execute::command_args!("systemctl", "reload-or-restart", "--user", "waybar.service")
        .execute()
        .ok();
}

/// runs wallust with flags from image metadata if available
pub fn from_wallpaper<P>(wallpaper_info: &WallInfo, wallpaper: P)
where
    P: AsRef<Path> + std::fmt::Debug,
{
    let mut wallust =
        execute::command_args!("wallust", "run", "--check-contrast", "--dynamic-threshold");

    // normalize the options for wallust
    let WallInfo { wallust: opts, .. } = wallpaper_info;

    // split opts into flags
    if !opts.is_empty() {
        let opts: Vec<&str> = opts.split(' ').map(str::trim).collect();
        wallust.args(opts);
    }

    wallust
        .arg(wallpaper.as_ref())
        .execute()
        .expect("wallust: failed to set colors from wallpaper");
}

pub fn set_gtk_and_icon_theme(nixcolors: &NixColors, accent: &Rgb) {
    let variant = nixcolors
        .theme_accents
        .iter()
        .min_by_key(|(_, theme_color)| theme_color.distance_sq(accent))
        .expect("no closest theme color found")
        .0;

    // requires the single quotes to be GVariant compatible for dconf
    let gvariant = |v: &str| format!("'{v}'");

    let gtk_theme = format!("catppuccin-mocha-{variant}-compact");
    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/gtk-theme")
        .arg(gvariant(&gtk_theme))
        .execute()
        .expect("failed to apply gtk theme");

    // update qt (kvantum) theme
    let kvantum = full_path("~/.config/Kvantum/kvantum.kvconfig");
    if kvantum.exists() {
        let qt_theme = format!("catppuccin-mocha-{variant}");
        replace_in_file(kvantum, vec![(r"catppuccin-mocha-.*", &qt_theme)]);
    }

    // requires the single quotes to be GVariant compatible for dconf
    let icon_theme = format!("Tela-{variant}-dark");
    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/icon-theme")
        .arg(gvariant(&icon_theme))
        .execute()
        .expect("failed to apply icon theme");

    // update the icon theme for dunst and qt
    for file in [
        full_path("~/.cache/wallust/dunstrc"),
        full_path("~/.config/qt5ct/qt5ct.conf"),
        full_path("~/.config/qt6ct/qt6ct.conf"),
    ] {
        replace_in_file(file, vec![(r"Tela-.*-dark", &icon_theme)]);
    }

    // restart dunst
    execute::command_args!("systemctl", "reload-or-restart", "--user", "dunst.service")
        .execute()
        .ok();
}

pub fn set_waybar_colors(accent: &Rgb) {
    // get complementary color for complementary module classes
    let css_file = full_path("~/.config/waybar/style.css");

    let new_accent = format!("accent {};", accent.to_hex_str());
    let new_complementary = format!("complementary {};", accent.complementary().to_hex_str());

    let replacements = vec![
        // replace old foreground color with new complementary color
        (r"accent .*;", new_accent.as_str()),
        // replace complementary colors
        (r"complementary .*;", new_complementary.as_str()),
    ];
    replace_in_file(&css_file, replacements);

    // write persistent workspaces config to waybar
    #[cfg(feature = "hyprland")]
    {
        use crate::{nixjson::NixJson, rearranged_workspaces};
        use hyprland::{data::Monitors, shared::HyprData};

        // add / remove persistent workspaces to waybar before launching
        let cfg_file = full_path("~/.config/waybar/config.jsonc");

        let mut cfg: serde_json::Value =
            json::load(&cfg_file).unwrap_or_else(|_| panic!("unable to read waybar config"));

        let monitors = NixJson::new().monitors;
        let active_workspaces: HashMap<_, _> = Monitors::get()
            .expect("could not get monitors")
            .iter()
            .map(|mon| (mon.name.clone(), mon.active_workspace.id))
            .collect();

        let new_wksps: HashMap<String, Vec<i32>> =
            rearranged_workspaces(&monitors, &active_workspaces)
                .iter()
                .map(|(mon_name, wksps)| (mon_name.clone(), wksps.clone()))
                .collect();

        cfg["hyprland/workspaces"]["persistent-workspaces"] = serde_json::to_value(new_wksps)
            .expect("failed to convert rearranged workspaces to json");

        json::write(&cfg_file, &cfg).expect("failed to write updated waybar config");
    }
}
