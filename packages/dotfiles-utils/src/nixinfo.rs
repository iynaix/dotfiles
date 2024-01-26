use crate::json;
use serde::Deserialize;
use std::collections::HashMap;

#[derive(Debug, Clone, Default, Deserialize)]
pub struct Special {
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
    pub logo: String,
    pub special: Special,
    pub persistent_workspaces: bool,
    pub waybar_hidden: bool,
    pub monitors: Vec<NixMonitorInfo>,
    /// color0 - color15
    pub colors: HashMap<String, String>,
}

impl NixInfo {
    /// get nix info from ~/.config before wallust has processed it
    pub fn before() -> Self {
        json::load("~/.config/wallust/nix.json")
    }

    /// get nix info from ~/.cache after wallust has processed it
    pub fn after() -> Self {
        json::load("~/.cache/wallust/nix.json")
    }

    /// get a vec of colors without # prefix
    pub fn hyprland_colors(&self) -> Vec<String> {
        (1..16)
            .map(|n| {
                let k = format!("color{n}");
                format!(
                    "rgb({})",
                    self.colors
                        .get(&k)
                        .expect("color not found")
                        .replace('#', "")
                )
            })
            .collect()
    }
}
