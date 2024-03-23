use rand::seq::SliceRandom;
use serde::Deserialize;

use crate::{full_path, nixinfo::NixInfo};
use std::{
    fs,
    path::{Path, PathBuf},
};

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

fn filter_images(dir: &Path) -> impl Iterator<Item = String> {
    dir.read_dir()
        .unwrap_or_else(|_| panic!("could not read {:?}", &dir))
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    match ext.to_str() {
                        Some("jpg" | "jpeg" | "png") => return Some(path.to_str()?.to_string()),
                        _ => return None,
                    }
                }
            }

            None
        })
}

/// returns all files in the wallpaper directory, exlcluding the current wallpaper
pub fn all() -> Vec<String> {
    let curr = self::current().unwrap_or_default();

    filter_images(&self::dir())
        // do not include the current wallpaper
        .filter(|path| curr != *path)
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

pub fn random_from_dir(dir: &Path) -> String {
    filter_images(dir)
        .collect::<Vec<_>>()
        .choose(&mut rand::thread_rng())
        // use fallback image if not available
        .unwrap_or(&NixInfo::before().fallback)
        .to_string()
}

#[derive(Debug, Deserialize, Clone)]
pub struct WallInfo {
    pub filename: String,
    // faces is unused, keep it as a string
    pub faces: String,
    pub r1440x2560: String,
    pub r2256x1504: String,
    pub r3440x1440: String,
    pub r1920x1080: String,
    pub r1x1: String,
    pub wallust: String,
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
