use crate::json;
use serde::Deserialize;

#[derive(Clone, Default, Deserialize, Debug, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub struct NixMonitorInfo {
    pub name: String,
    pub workspaces: Vec<i32>,
    pub width: u16,
    pub height: u16,
    pub transform: u8,
}

impl NixMonitorInfo {
    pub fn layoutopts(&self, workspace: i32, is_nstack: bool) -> String {
        let mut opts = vec![workspace.to_string()];

        let is_vertical = self.transform == 1 || self.transform == 3;
        let is_ultrawide = f64::from(self.width) / f64::from(self.height) > 16.0 / 9.0;

        let orientation = format!(
            "layoutopt:{prefix}orientation:{orientation}",
            prefix = if is_nstack { "nstack-" } else { "" },
            orientation = if is_vertical { "top" } else { "left" }
        );
        opts.push(orientation);

        if is_nstack {
            let stacks = if is_ultrawide || is_vertical {
                "3"
            } else {
                "2"
            };
            opts.push(format!("layoutopt:nstack-stacks:{stacks}"));
        }

        if is_nstack && !is_ultrawide {
            opts.push("layoutopt:nstack-mfact:0.0".to_string());
        }

        opts.join(",")
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
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
