use execute::Execute;
use itertools::Itertools;
use rayon::prelude::*;
use rexiv2::Metadata;
use serde::Deserialize;

use crate::{full_path, nixjson::NixJson};
use std::{
    collections::{HashMap, HashSet},
    path::{Path, PathBuf},
    process::Stdio,
};

pub fn dir() -> PathBuf {
    full_path("~/Pictures/Wallpapers")
}

pub fn current() -> Option<String> {
    dirs::runtime_dir()
        .map(|runtime_dir| runtime_dir.join("current_wallpaper"))
        .and_then(|runtime_file| std::fs::read_to_string(runtime_file).ok())
}

pub fn filter_images<P>(dir: P) -> impl Iterator<Item = String>
where
    P: AsRef<Path> + std::fmt::Debug,
{
    dir.as_ref()
        .read_dir()
        .unwrap_or_else(|_| panic!("could not read {:?}", &dir))
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.is_file()
                && let Some(ext) = path.extension()
            {
                return matches!(ext.to_str(), Some("jpg" | "jpeg" | "png" | "webp")).then(|| {
                    path.to_str()
                        .expect("could not convert path to str")
                        .to_string()
                });
            }

            None
        })
}

/// sets the wallpaper for all monitors
pub fn set<P>(wallpaper: P)
where
    P: AsRef<Path> + std::fmt::Debug,
{
    #[derive(Debug, Deserialize)]
    #[serde(rename_all = "camelCase")]
    pub struct WlrMonitor {
        pub enabled: bool,
        pub name: String,
    }

    // write current wallpaper to $XDG_RUNTIME_DIR/current_wallpaper
    std::fs::write(
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("current_wallpaper"),
        wallpaper
            .as_ref()
            .to_str()
            .expect("could not convert wallpaper path to str"),
    )
    .ok();

    // set the wallpaper with cropping
    // set the wallpaper per monitor, use wlr-randr so it is wm agnostic
    let wlr_cmd = execute::command_args!("wlr-randr", "--json")
        .stdout(Stdio::piped())
        .execute_output()
        .expect("failed to run wlr-randr");
    let wlr_json = String::from_utf8(wlr_cmd.stdout).expect("invalid utf8 from wlr-randr");
    let monitors: Vec<WlrMonitor> = serde_json::from_str(&wlr_json).expect("failed to parse json");

    let wallpaper = wallpaper
        .as_ref()
        .to_str()
        .expect("could not convert wallpaper path to str")
        .to_string();
    monitors
        .par_iter()
        .filter(|mon| mon.enabled)
        .for_each(|mon| {
            //
            execute::command_args!("noctalia-shell", "ipc", "call", "wallpaper", "set")
                .arg(&wallpaper)
                .arg(&mon.name)
                .spawn()
                .unwrap_or_else(|_| panic!("failed to set wallpaper: {wallpaper}"))
                .wait()
                .expect("failed to wait for noctalia wallpaper set");
        });
}

/// reloads the wallpaper
pub fn reload() {
    // clear noctalia cache to force the wallpaper to be reloaded
    let noctalia_cache = full_path("~/.cache/noctalia/images/wallpapers/large");
    std::fs::remove_dir_all(&noctalia_cache).expect("unable to clear noctalia cache");
    std::fs::create_dir(&noctalia_cache).ok();

    set(current().expect("no current wallpaper set"));
}

pub fn random_from_dir<P>(dir: P) -> String
where
    P: AsRef<Path> + std::fmt::Debug,
{
    if !dir.as_ref().exists() {
        return NixJson::new().fallback_wallpaper;
    }

    let wallpapers = filter_images(dir).collect_vec();
    if wallpapers.is_empty() {
        NixJson::new().fallback_wallpaper
    } else {
        wallpapers[fastrand::usize(..wallpapers.len())].clone()
    }
}

/// euclid's algorithm to find the greatest common divisor
const fn gcd(mut a: u32, mut b: u32) -> u32 {
    while b != 0 {
        let tmp = b;
        b = a % b;
        a = tmp;
    }
    a
}

#[derive(Debug, Clone)]
pub struct WallInfo {
    pub path: PathBuf,
    pub geometries: HashMap<String, String>,
}

impl WallInfo {
    pub fn new_from_file<P>(img: P) -> Self
    where
        P: AsRef<Path> + std::fmt::Debug,
    {
        let meta = Metadata::new_from_path(img.as_ref()).expect("could not init new metadata");

        let mut crops = HashMap::new();

        for tag in meta.get_xmp_tags().expect("unable to read xmp tags") {
            if tag.starts_with("Xmp.wallfacer.crop.") {
                let aspect = tag
                    .strip_prefix("Xmp.wallfacer.crop.")
                    .expect("could not strip crop prefix");
                let geom = meta.get_tag_string(&tag).expect("could not get crop tag");

                crops.insert(aspect.to_string(), geom);
            }
        }

        Self {
            path: img.as_ref().to_path_buf(),
            geometries: crops,
        }
    }

    pub fn get_geometry(&self, width: u32, height: u32) -> Option<(f64, f64, f64, f64)> {
        self.get_geometry_str(width, height).and_then(|geom| {
            let geometry = geom
                .split(['+', 'x'])
                .flat_map(str::parse::<f64>)
                .collect_vec();

            match geometry.as_slice() {
                &[w, h, x, y] => Some((w, h, x, y)),
                _ => None,
            }
        })
    }

    pub fn get_geometry_str(&self, width: u32, height: u32) -> Option<&str> {
        let divisor = gcd(width, height);
        self.geometries
            .get(&format!("{}x{}", width / divisor, height / divisor))
            .map(std::string::String::as_str)
    }
}

pub fn history() -> Vec<(PathBuf, chrono::DateTime<chrono::FixedOffset>)> {
    let Ok(history_csv) = std::fs::File::open(full_path("~/Pictures/wallpapers_history.csv"))
    else {
        return Vec::new();
    };

    let images: HashSet<String> = dir()
        .read_dir()
        .expect("unable to read wallpapers dir")
        .flatten()
        .map(|entry| entry.file_name().to_string_lossy().to_string())
        .collect();

    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(false)
        .from_reader(std::io::BufReader::new(history_csv));

    rdr.records()
        .flatten()
        .filter_map(|row| {
            let (Some(fname), Some(dt_str)) = (row.get(0), row.get(1)) else {
                return None;
            };

            if !images.contains(fname) {
                return None;
            }

            chrono::DateTime::parse_from_rfc3339(dt_str)
                .ok()
                .map(|dt| (dir().join(fname), dt))
        })
        .sorted_by_key(|(_, dt)| *dt)
        .rev()
        .collect_vec()
}
