use std::path::PathBuf;

use crate::{full_path, json};
use serde::Deserialize;
use sha2::Digest;

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

    /// get the noctalia image cache path for the given image
    pub fn noctalia_wallpaper_cache_path(&self, img: &str) -> PathBuf {
        let image_cache_dir = full_path("~/.cache/noctalia/images/wallpapers/large");

        // get the modification time or unknown
        let mtime = std::fs::metadata(img)
            .and_then(|m| m.modified())
            .map_or_else(
                |_| "unknown".to_string(),
                |time| {
                    time.duration_since(std::time::SystemTime::UNIX_EPOCH)
                        .map_or_else(
                            |_| "unknown".to_string(),
                            |elapsed| elapsed.as_secs().to_string(),
                        )
                },
            );

        let dimensions = if self.transform % 2 == 1 {
            format!("{}x{}", self.height, self.width)
        } else {
            format!("{}x{}", self.width, self.height)
        };
        let hash_str = format!("{img}@{dimensions}@{mtime}");

        image_cache_dir.join(format!(
            "{}.png",
            hex::encode(sha2::Sha256::digest(hash_str.as_bytes()))
        ))
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
