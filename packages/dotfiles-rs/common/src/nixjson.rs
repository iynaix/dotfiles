use crate::{MIN_ULTRAWIDE_RATIO, json};
use serde::Deserialize;

#[derive(Clone, Default, Deserialize, Debug, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct NixMonitor {
    pub name: String,
    pub workspaces: Vec<i32>,
    pub width: u32,
    pub height: u32,
    pub transform: u8,
    pub scale: f64,
    pub default_workspace: i32,
}

impl NixMonitor {
    /// dimensions of the monitor after scaling and transform
    pub fn final_dimensions(&self) -> (u32, u32) {
        let (w, h) = if self.transform % 2 == 1 {
            (self.height, self.width)
        } else {
            (self.width, self.height)
        };

        if (self.scale - 1.0).abs() < f64::EPSILON {
            (w, h)
        } else {
            (
                (f64::from(w) / self.scale) as u32,
                (f64::from(h) / self.scale) as u32,
            )
        }
    }

    pub fn layoutopts(&self, workspace: i32, is_nstack: bool) -> String {
        let mut opts = vec![workspace.to_string()];

        let is_vertical = self.transform % 2 == 1;
        let is_ultrawide = f64::from(self.width) / f64::from(self.height) > MIN_ULTRAWIDE_RATIO;

        let orientation = format!(
            "layoutopt:{prefix}orientation:{orientation}",
            prefix = if is_nstack { "nstack-" } else { "" },
            orientation = if is_vertical { "top" } else { "left" }
        );
        opts.push(orientation);

        if is_nstack {
            let stacks = if is_ultrawide || is_vertical { 3 } else { 2 };
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
pub struct NixJson {
    pub wallpaper: String,
    pub fallback: String,
    pub colorscheme: Option<String>,
    pub host: String,
    pub niri_blur: Option<bool>,
    pub monitors: Vec<NixMonitor>,
}

impl Default for NixJson {
    fn default() -> Self {
        Self::new()
    }
}

impl NixJson {
    /// get nix info from ~/.config before wallust has processed it
    pub fn new() -> Self {
        json::load("~/.config/wallust/templates/nix.json")
            .unwrap_or_else(|_| panic!("unable to read nix.json"))
    }
}
