use rand::seq::SliceRandom;

use crate::{cmd, cmd_output, full_path, json, nixinfo::NixInfo, CmdOutput};
use std::{collections::HashMap, fs, path::PathBuf};

pub fn dir() -> PathBuf {
    full_path("~/Pictures/Wallpapers")
}

pub fn current() -> Option<String> {
    let curr = NixInfo::after().wallpaper;

    let wallpaper = {
        if curr != "./foo/bar.text" {
            Some(curr)
        } else {
            fs::read_to_string(full_path("~/.cache/current_wallpaper")).ok()
        }
    };

    Some(
        wallpaper
            .expect("no wallpaper found")
            .replace("/persist", ""),
    )
}

/// returns all files in the wallpaper directory, exlcluding the current wallpaper
pub fn all() -> Vec<String> {
    let curr = self::current().unwrap_or_default();

    self::dir()
        .read_dir()
        .unwrap()
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    match ext.to_str() {
                        Some("jpg") | Some("jpeg") | Some("png") if curr != *path.to_str()? => {
                            return Some(path.to_str()?.to_string())
                        }
                        _ => return None,
                    }
                }
            }

            None
        })
        .collect()
}

pub fn random() -> String {
    if self::dir().exists() {
        self::all()
            .choose(&mut rand::thread_rng())
            // use fallback image if not available
            .unwrap_or(&NixInfo::before().fallback)
            .to_string()
    } else {
        NixInfo::before().fallback
    }
}

/// creates a directory with randomly ordered wallpapers for imv to display
pub fn randomize_wallpapers() -> String {
    let output_dir = full_path("~/.cache/wallpapers_random");
    let output_dir = output_dir.to_str().unwrap();

    // delete existing dir and recreate it
    fs::remove_dir_all(output_dir).unwrap_or(());
    fs::create_dir_all(output_dir).expect("could not create random wallpaper dir");

    // shuffle all wallpapers
    let mut rng = rand::thread_rng();
    let mut shuffled = self::all();
    shuffled.shuffle(&mut rng);

    let prefix_len = shuffled.len().to_string().len();
    for (idx, path) in shuffled.iter().enumerate() {
        let (_, img) = path.rsplit_once('/').unwrap();
        let new_path = format!("{output_dir}/{:0>1$}-{img}", idx, prefix_len);
        // create symlinks
        std::os::unix::fs::symlink(path, new_path).expect("failed to create symlink");
    }

    output_dir.to_string()
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
        CmdOutput::Stdout,
    )
    .iter()
    .find(|line| line.contains("org.pwmt.zathura"))
    {
        let zathura_pid = zathura_pid_raw.split('"').max_by_key(|s| s.len()).unwrap();

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
pub fn wallust_apply_colors() {
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
                format!("rgb({})", cs.colors.get(&k).unwrap().replace('#', ""))
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
        cmd(["killall", "-SIGUSR2", ".waybar-wrapped"]);
    }

    // reload gtk theme
    // reload_gtk()
}
