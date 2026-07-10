use crate::{full_path, json};
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

    pub fn layoutopts(&self, workspace: i32) -> String {
        let mut opts = vec![workspace.to_string()];

        let is_vertical = self.transform % 2 == 1;

        let orientation = format!(
            "layoutopt:orientation:{orientation}",
            orientation = if is_vertical { "top" } else { "left" }
        );
        opts.push(orientation);

        opts.join(",")
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NixJson {
    pub fallback_wallpaper: String,
    pub host: String,
    pub monitors: Vec<NixMonitor>,
}

impl Default for NixJson {
    fn default() -> Self {
        Self::load()
    }
}

impl NixJson {
    pub fn load() -> Self {
        json::load(full_path("~/.local/state/nix.json"))
            .unwrap_or_else(|_| panic!("error reading nix.json"))
    }
}
