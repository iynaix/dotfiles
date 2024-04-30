use crate::json;
use serde::Deserialize;
use std::collections::HashMap;

#[derive(Debug, Clone, Default, Deserialize)]
pub struct ColorsSpecial {
    pub background: String,
    pub foreground: String,
    pub cursor: String,
}

#[derive(Clone, Default, Deserialize, Debug)]
pub struct NixMonitorInfo {
    pub name: String,
    pub workspaces: Vec<i32>,
}

#[derive(Debug, Clone, Default, Deserialize)]
pub struct NixInfo {
    pub wallpaper: String,
    pub fallback: String,
    pub colorscheme: Option<String>,
    pub special: ColorsSpecial,
    pub host: String,
    pub persistent_workspaces: Option<bool>,
    // output cropped wallpaper as jpg for hyprlock
    pub monitors: Vec<NixMonitorInfo>,
    /// color0 - color15
    pub colors: HashMap<String, String>,
    /// for selecting best gtk theme and icon variants for wallpaper
    pub theme_accents: HashMap<String, String>,
}

/// get a vec of colors without # prefix
pub fn hyprland_colors<S: ::std::hash::BuildHasher>(
    colors: &HashMap<String, String, S>,
) -> Vec<String> {
    (1..16)
        .map(|n| {
            let k = format!("color{n}");
            format!(
                "rgb({})",
                colors
                    .get(&k)
                    .unwrap_or_else(|| panic!("key {k} not found"))
                    .replace('#', "")
            )
        })
        .collect()
}

impl NixInfo {
    /// get nix info from ~/.config before wallust has processed it
    pub fn before() -> Self {
        json::load("~/.config/wallust/nix.json")
            .unwrap_or_else(|_| panic!("unable to read ~/.config/wallust/nix.json"))
    }

    /// get nix info from ~/.cache after wallust has processed it
    pub fn after() -> Self {
        json::load("~/.cache/wallust/nix.json")
            .unwrap_or_else(|_| panic!("unable to read ~/.cache/wallust/nix.json"))
    }
}
