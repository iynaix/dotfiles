use rand::seq::SliceRandom;

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
