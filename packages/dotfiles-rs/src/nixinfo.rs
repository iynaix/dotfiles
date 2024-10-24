use crate::json;
use serde::Deserialize;

#[derive(Clone, Default, Deserialize, Debug)]
pub struct NixMonitorInfo {
    pub name: String,
    pub workspaces: Vec<i32>,
}

#[derive(Debug, Deserialize)]
pub struct NixInfo {
    pub wallpaper: String,
    pub fallback: String,
    pub colorscheme: Option<String>,
    pub host: String,
    // waybar options
    pub waybar_persistent_workspaces: Option<bool>,
    pub monitors: Vec<NixMonitorInfo>,
}

impl Default for NixInfo {
    fn default() -> Self {
        Self::new()
    }
}

impl NixInfo {
    /// get nix info from ~/.config before wallust has processed it
    pub fn new() -> Self {
        json::load("~/.config/wallust/templates/nix.json")
            .unwrap_or_else(|_| panic!("unable to read nix.json"))
    }
}
