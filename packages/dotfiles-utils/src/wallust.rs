use std::collections::HashMap;

use crate::{cmd, cmd_output, full_path, json, nixinfo::NixInfo, CmdOutput, WAYBAR_CLASS};

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

    // refresh waifufetch
    cmd(["killall", "-SIGUSR2", "waifufetch"]);

    if cfg!(feature = "hyprland") {
        // sleep to prevent waybar race condition
        std::thread::sleep(std::time::Duration::from_secs(1));

        // refresh waybar
        cmd(["killall", "-SIGUSR2", WAYBAR_CLASS]);
    }

    // reload gtk theme
    // reload_gtk()
}
