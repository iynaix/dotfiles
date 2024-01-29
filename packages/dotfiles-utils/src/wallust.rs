use std::{collections::HashMap, process::Command};

use crate::{
    cmd, cmd_output, full_path, json, nixinfo::NixInfo, wallpaper::WallInfo, CmdOutput,
    WAYBAR_CLASS,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum Backend {
    Full,
    #[default]
    Resized,
    Wal,
    Thumb,
    FastResize,
    Kmeans,
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum Colorspace {
    #[default]
    Lab,
    LabMixed,
    LabFast,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum Generation {
    Interpolate,
    Complementary,
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum Palette {
    Dark,
    #[default]
    Dark16,
    HardDark,
    HardDark16,
    SoftDark,
    SoftDark16,
    DarkComp,
    DarkComp16,
    HardDarkComp,
    HardDarkComp16,
    SoftDarkComp,
    SoftDarkComp16,
}

#[derive(Debug, Default, Deserialize, Clone)]
pub struct Options {
    pub backend: Option<Backend>,
    pub colorspace: Option<Colorspace>,
    pub check_contrast: Option<bool>,
    pub generation: Option<Generation>,
    pub palette: Option<Palette>,
    pub saturation: Option<i32>,
    pub threshold: Option<i32>,
}

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
        let colorscheme_file = full_path(format!("~/.config/wallust/{theme}.json"));
        cmd([
            "wallust",
            "cs",
            colorscheme_file.to_str().expect("invalid colorscheme file"),
        ]);
    } else {
        cmd(["wallust", "theme", &theme]);
    }
}

fn refresh_zathura() {
    if let Some(zathura_pid_raw) = cmd_output(
        [
            "dbus-send",
            "--print-reply",
            "--dest=org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus.ListNames",
        ],
        &CmdOutput::Stdout,
    )
    .iter()
    .find(|line| line.contains("org.pwmt.zathura"))
    {
        let zathura_pid = zathura_pid_raw
            .split('"')
            .max_by_key(|s| s.len())
            .expect("could not extract zathura pid");

        // send message to zathura via dbus
        cmd([
            "dbus-send",
            "--type=method_call",
            &format!("--dest={zathura_pid}"),
            "/org/pwmt/zathura",
            "org.pwmt.zathura.ExecuteCommand",
            "string:source",
        ]);
    }
}

/// applies the wallust colors to various applications
pub fn apply_colors() {
    let c = if full_path("~/.cache/wallust/nix.json").exists() {
        NixInfo::after().hyprland_colors()
    } else {
        #[derive(serde::Deserialize)]
        struct Colorscheme {
            colors: HashMap<String, String>,
        }

        let cs_path = full_path("~/.config/wallust/catppuccin-mocha.json");
        let cs: Colorscheme = json::load(cs_path);

        (1..16)
            .map(|n| {
                let k = format!("color{n}");
                format!(
                    "rgb({})",
                    cs.colors.get(&k).expect("color not found").replace('#', "")
                )
            })
            .collect()
    };

    if cfg!(feature = "hyprland") {
        // update borders
        cmd([
            "hyprctl",
            "keyword",
            "general:col.active_border",
            &format!("{} {} 45deg", c[4], c[0]),
        ]);
        cmd(["hyprctl", "keyword", "general:col.inactive_border", &c[0]]);

        // pink border for monocle windows
        cmd([
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},fullscreen:1", &c[5]),
        ]);
        // teal border for floating windows
        cmd([
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},floating:1", &c[6]),
        ]);
        // yellow border for sticky (must be floating) windows
        cmd([
            "hyprctl",
            "keyword",
            "windowrulev2",
            "bordercolor",
            &format!("{},pinned:1", &c[3]),
        ]);
    }

    // refresh zathura
    refresh_zathura();

    // refresh cava
    cmd(["killall", "-SIGUSR2", "cava"]);

    // refresh wfetch
    cmd(["killall", "-SIGUSR2", "wfetch"]);

    if cfg!(feature = "hyprland") {
        // sleep to prevent waybar race condition
        std::thread::sleep(std::time::Duration::from_secs(1));

        // refresh waybar
        cmd(["killall", "-SIGUSR2", WAYBAR_CLASS]);
    }

    // reload gtk theme
    // reload_gtk()
}

/// adds an argument to wallust if available
fn add_arg<Arg>(cmd: &mut Command, name: &str, value: &Option<Arg>)
where
    Arg: Serialize,
{
    if let Some(value) = value {
        cmd.arg(format!("--{name}"));
        let parsed = serde_json::to_string(value)
            .unwrap_or_else(|_| panic!("failed to serialize wallust {name}"));
        cmd.arg(parsed);
    }
}

/// runs wallust with options from wallpapers.json
pub fn from_wallpaper(wallpaper_info: &Option<WallInfo>, wallpaper: &str) {
    let mut wallust = Command::new("wallust");
    wallust.arg("run");

    // normalize the options for wallust
    if let Some(WallInfo {
        wallust: Some(opts),
        ..
    }) = wallpaper_info
    {
        if opts.check_contrast == Some(true) {
            wallust.arg("--check-contrast");
        }
        add_arg(&mut wallust, "backend", &opts.backend);
        add_arg(&mut wallust, "colorspace", &opts.colorspace);
        add_arg(&mut wallust, "generation", &opts.generation);
        add_arg(&mut wallust, "palette", &opts.palette);
        add_arg(&mut wallust, "saturation", &opts.saturation);
        add_arg(&mut wallust, "threshold", &opts.threshold);
    }

    wallust
        .arg(wallpaper)
        .spawn()
        .expect("wallust: failed to set colors from wallpaper");
}
