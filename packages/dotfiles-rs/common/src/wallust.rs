use crate::{
    colors::{NixColors, Rgb},
    full_path, kill_wrapped_process,
    wallpaper::WallInfo,
};
use core::panic;
use execute::Execute;
use image::ImageReader;
use itertools::Itertools;
use regex::Regex;
use std::{collections::HashMap, path::Path};

pub fn apply_theme(theme: &str) {
    execute::command_args!("wallust", "theme", &theme)
        .execute()
        .unwrap_or_else(|_| panic!("failed to apply wallust theme {theme}"));
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
pub fn wallust_colors_by_usage(wallpaper: &str, wallust_colors: &[Rgb]) -> (Rgb, Vec<Rgb>) {
    // open wallpaper and read colors
    let img = ImageReader::open(wallpaper)
        .expect("could not open image")
        .decode()
        .expect("could not decode image")
        .to_rgb8();

    // initialize with each accent as a color might not be used
    let mut color_counts: HashMap<Rgb, i32> =
        wallust_colors.iter().map(|a| (a.clone(), 0)).collect();

    // sample middle of every 15x15 pixel block
    for x in (7..img.width()).step_by(15) {
        for y in (7..img.height()).step_by(15) {
            let px = img.get_pixel(x, y);

            let closest_color = wallust_colors
                .iter()
                .min_by_key(|color| {
                    color.distance_sq(&Rgb {
                        r: px[0],
                        g: px[1],
                        b: px[2],
                    })
                })
                .expect("could not find closest color");

            // store the closest color
            *color_counts.entry(closest_color.clone()).or_default() += 1;
        }
    }

    let colors = color_counts
        .into_iter()
        .sorted_by(|a, b| b.1.cmp(&a.1))
        .map(|(color, _)| color)
        .collect_vec();

    let waybar_color = colors.last().expect("color_counts is empty");

    (waybar_color.clone(), colors)
}

/// applies the wallust colors to various applications
pub fn apply_colors() {
    if let Ok(nixcolors) = NixColors::new() {
        // ignore black and white
        let colors = nixcolors
            .filter_colors(&["color0", "color7", "color8", "color15"])
            .into_values()
            .collect_vec();

        let (waybar_accent, colors_by_usage) =
            wallust_colors_by_usage(&nixcolors.wallpaper, &colors);

        #[cfg(feature = "hyprland")]
        apply_hyprland_colors(&colors_by_usage, &nixcolors.colors);

        #[cfg(feature = "niri")]
        apply_niri_colors(&colors_by_usage, &nixcolors.colors);

        // set the waybar accent color to have more contrast
        set_waybar_colors(&waybar_accent);

        set_gtk_and_icon_theme(&nixcolors, &colors_by_usage[0]);
    } else {
        let idx = wallust_themes::COLS_KEY
            .into_iter()
            .position(|k| k == "Tokyo-Night")
            .expect("failed to find Tokyo-Night");

        // rust-analyzer keeps warning about this until file is saved?
        #[allow(unused_variables)]
        let colors: HashMap<String, Rgb> = wallust_themes::COLS_VALUE[idx]
            .into_iter()
            .enumerate()
            .map(|(i, c)| (format!("color{i}"), Rgb::from_wallust_theme_color(c)))
            .take(16)
            .collect();

        #[cfg(feature = "hyprland")]
        apply_hyprland_colors(&[], &colors);

        #[cfg(feature = "niri")]
        apply_niri_colors(&[], &colors);
    }

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
    let gtk_theme = if variant == "Default" {
        "Tokyonight-Dark-Compact".to_string()
    } else {
        format!("Tokyonight-{variant}-Dark-Compact")
    };

    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/gtk-theme")
        .arg(gvariant(&gtk_theme))
        .execute()
        .expect("failed to apply gtk theme");

    // requires the single quotes to be GVariant compatible for dconf
    let icon_theme = format!("Tela-{variant}-dark");
    execute::command_args!("dconf", "write", "/org/gnome/desktop/interface/icon-theme")
        .arg(gvariant(&icon_theme))
        .execute()
        .expect("failed to apply icon theme");

    // update the icon theme for dunst and qt
    for file in [
        full_path("~/.config/dunst/dunstrc"),
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
            crate::json::load(&cfg_file).unwrap_or_else(|_| panic!("unable to read waybar config"));

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

        crate::json::write(&cfg_file, &cfg).expect("failed to write updated waybar config");
    }
}
