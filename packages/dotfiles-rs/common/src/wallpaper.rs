use itertools::Itertools;
use rexiv2::Metadata;

use crate::{full_path, nixinfo::NixInfo, swww::Swww, wallust};
use std::{
    collections::{HashMap, HashSet},
    path::{Path, PathBuf},
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
            if path.is_file() {
                if let Some(ext) = path.extension() {
                    return matches!(ext.to_str(), Some("jpg" | "jpeg" | "png" | "webp")).then(
                        || {
                            path.to_str()
                                .expect("could not convert path to str")
                                .to_string()
                        },
                    );
                }
            }

            None
        })
}

/// sets the wallpaper and reloads the wallust theme
pub fn set<P>(wallpaper: P, transition: Option<&String>)
where
    P: AsRef<Path> + std::fmt::Debug,
{
    let wallpaper_info = WallInfo::new_from_file(&wallpaper);

    // use colorscheme set from nix if available
    if let Some(cs) = NixInfo::new().colorscheme {
        wallust::apply_theme(&cs);
    } else {
        wallust::from_wallpaper(&wallpaper_info, &wallpaper);
    }

    // set the wallpaper with cropping
    Swww::new(&wallpaper).run(&wallpaper_info, transition);

    // do wallust earlier to create the necessary templates
    wallust::apply_colors();
}

/// reloads the wallpaper and wallust theme
pub fn reload(transition: Option<&String>) {
    set(current().expect("no current wallpaper set"), transition);
}

pub fn random_from_dir<P>(dir: P) -> String
where
    P: AsRef<Path> + std::fmt::Debug,
{
    if !dir.as_ref().exists() {
        return NixInfo::new().fallback;
    }

    let wallpapers = filter_images(dir).collect_vec();
    if wallpapers.is_empty() {
        NixInfo::new().fallback
    } else {
        wallpapers[fastrand::usize(..wallpapers.len())].to_string()
    }
}

/// euclid's algorithm to find the greatest common divisor
const fn gcd(mut a: i32, mut b: i32) -> i32 {
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
    pub wallust: String,
}

impl WallInfo {
    pub fn new_from_file<P>(img: P) -> Self
    where
        P: AsRef<Path> + std::fmt::Debug,
    {
        let meta = Metadata::new_from_path(img.as_ref()).expect("could not init new metadata");

        let mut crops = HashMap::new();
        let mut wallust = String::new();

        for tag in meta.get_xmp_tags().expect("unable to read xmp tags") {
            if tag.starts_with("Xmp.wallfacer.crop.") {
                let aspect = tag
                    .strip_prefix("Xmp.wallfacer.crop.")
                    .expect("could not strip crop prefix");
                let geom = meta.get_tag_string(&tag).expect("could not get crop tag");

                crops.insert(aspect.to_string(), geom);
            }

            if tag == "Xmp.wallfacer.wallust" {
                wallust = meta
                    .get_tag_string(&tag)
                    .expect("could not get wallust tag");
            }
        }

        Self {
            path: img.as_ref().to_path_buf(),
            geometries: crops,
            wallust,
        }
    }

    pub fn get_geometry(&self, width: i32, height: i32) -> Option<(f64, f64, f64, f64)> {
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

    pub fn get_geometry_str(&self, width: i32, height: i32) -> Option<&String> {
        let divisor = gcd(width, height);
        self.geometries
            .get(&format!("{}x{}", width / divisor, height / divisor))
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
