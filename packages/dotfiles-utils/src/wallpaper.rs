use rand::seq::SliceRandom;
use serde::Deserialize;

use crate::{full_path, nixinfo::NixInfo, wallust};
use std::{
    collections::HashMap,
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

/// creates a directory with randomly ordered wallpapers for imv to display
pub fn randomize_wallpapers() -> String {
    let output_dir = full_path("~/.cache/wallpapers_random");
    let output_dir = output_dir.to_str().expect("invalid output dir");

    // delete existing dir and recreate it
    fs::remove_dir_all(output_dir).unwrap_or(());
    fs::create_dir_all(output_dir).expect("could not create random wallpaper dir");

    // shuffle all wallpapers
    let mut rng = rand::thread_rng();
    let mut shuffled = self::all();
    shuffled.shuffle(&mut rng);

    let prefix_len = shuffled.len().to_string().len();
    for (idx, path) in shuffled.iter().enumerate() {
        let (_, img) = path.rsplit_once('/').expect("could not extract image name");
        let new_path = format!("{output_dir}/{idx:0>prefix_len$}-{img}");
        // create symlinks
        std::os::unix::fs::symlink(path, new_path).expect("failed to create symlink");
    }

    output_dir.to_string()
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
    pub wallust: Option<wallust::Options>,
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

/// reads the wallpaper info from wallpapers.json
pub fn info(image: &String) -> Option<WallInfo> {
    let wallpapers_json = full_path("~/Pictures/Wallpapers/wallpapers.json");
    if !wallpapers_json.exists() {
        return None;
    }

    // convert image to path
    let image = Path::new(image);
    let fname = image
        .file_name()
        .expect("invalid image path")
        .to_str()
        .expect("could not convert image path to str");

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_json).expect("could not open wallpapers.json"),
    );
    let mut crops: HashMap<String, WallInfo> =
        serde_json::from_reader(reader).expect("could not parse wallpapers.json");
    crops.remove(fname)
}
