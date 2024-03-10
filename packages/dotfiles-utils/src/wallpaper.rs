use rand::seq::SliceRandom;
use serde::Deserialize;

use crate::{full_path, nixinfo::NixInfo};
use std::{fs, path::PathBuf};

pub fn dir() -> PathBuf {
    full_path("~/Pictures/Wallpapers")
}

pub fn current() -> Option<String> {
    let curr = NixInfo::after().wallpaper;

    let wallpaper = {
        if curr == "./foo/bar.text" {
            fs::read_to_string(full_path("~/.cache/current_wallpaper")).ok()
        } else {
            Some(curr)
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
        .expect("could not read wallpaper dir")
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    match ext.to_str() {
                        Some("jpg" | "jpeg" | "png") if curr != *path.to_str()? => {
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

#[derive(Debug, Default, Deserialize, Clone)]
pub struct Face {
    #[serde(rename = "0")]
    pub xmin: u32,
    #[serde(rename = "1")]
    pub xmax: u32,
    #[serde(rename = "2")]
    pub ymin: u32,
    #[serde(rename = "3")]
    pub ymax: u32,
}

#[derive(Debug, Deserialize, Clone)]
pub struct WallInfo {
    pub faces: Vec<Face>,
    #[serde(rename = "1440x2560")]
    pub r1440x2560: String,
    #[serde(rename = "2256x1504")]
    pub r2256x1504: String,
    #[serde(rename = "3440x1440")]
    pub r3440x1440: String,
    #[serde(rename = "1920x1080")]
    pub r1920x1080: String,
    #[serde(rename = "1x1")]
    pub r1x1: String,
    pub wallust: Option<String>,
}

impl WallInfo {
    pub const fn get_geometry(&self, width: i32, height: i32) -> Option<&String> {
        match (width, height) {
            (1440, 2560) => Some(&self.r1440x2560),
            (2256, 1504) => Some(&self.r2256x1504),
            (3440, 1440) => Some(&self.r3440x1440),
            (1920, 1080) => Some(&self.r1920x1080),
            (1, 1) => Some(&self.r1x1),
            _ => None,
        }
    }
}
