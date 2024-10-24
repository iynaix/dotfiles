use itertools::Itertools;
use serde::{de, Deserialize, Deserializer};

use crate::{filename, full_path, nixinfo::NixInfo, swww::Swww, wallust};
use std::{
    collections::HashMap,
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

fn filter_images<P>(dir: P) -> impl Iterator<Item = String>
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

/// reads the wallpaper info from wallpapers.csv
fn get_wallpaper_info(wallpaper: &str) -> Option<WallInfo> {
    let wallpapers_csv = full_path("~/Pictures/Wallpapers/wallpapers.csv");
    if !wallpapers_csv.exists() {
        return None;
    }

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_csv).expect("could not open wallpapers.csv"),
    );

    let fname = filename(wallpaper);
    let mut rdr = csv::Reader::from_reader(reader);
    rdr.deserialize::<WallInfo>()
        .flatten()
        .find(|line| line.filename == fname)
}

/// sets the wallpaper and reloads the wallust theme
pub fn set(wallpaper: &str, transition: &Option<String>) {
    let wallpaper_info = get_wallpaper_info(wallpaper);

    // use colorscheme set from nix if available
    if let Some(cs) = NixInfo::new().colorscheme {
        wallust::apply_theme(&cs);
    } else {
        wallust::from_wallpaper(&wallpaper_info, wallpaper);
    }

    // set the wallpaper with cropping
    Swww::new(wallpaper).run(wallpaper_info, transition);

    // do wallust earlier to create the necessary templates
    wallust::apply_colors();
}

/// reloads the wallpaper and wallust theme
pub fn reload(transition: &Option<String>) {
    set(&current().expect("no current wallpaper set"), transition);
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
    pub filename: String,
    pub width: u32,
    pub height: u32,
    pub geometries: HashMap<String, String>,
    pub wallust: String,
}

impl WallInfo {
    pub fn get_geometry(&self, width: i32, height: i32) -> Option<(f64, f64, f64, f64)> {
        self.get_geometry_str(width, height).and_then(|geom| {
            let geometry = geom
                .split(['+', 'x'])
                .filter_map(|s| s.parse::<f64>().ok())
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

impl<'de> Deserialize<'de> for WallInfo {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        #[serde(field_identifier, rename_all = "lowercase")]
        enum Field {
            Filename,
            Faces,
            Geometries,
            Wallust,
        }

        struct WallInfoVisitor;

        impl<'de> de::Visitor<'de> for WallInfoVisitor {
            type Value = WallInfo;

            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("struct WallInfo2")
            }

            fn visit_map<V>(self, mut map: V) -> Result<Self::Value, V::Error>
            where
                V: de::MapAccess<'de>,
            {
                let mut filename = None;
                let mut width = None;
                let mut height = None;
                let mut geometries = HashMap::new();
                let mut wallust = None;

                while let Some((key, value)) = map.next_entry::<&str, String>()? {
                    match key {
                        "filename" => {
                            filename = Some(value);
                        }
                        "width" => {
                            width = Some(value.parse::<u32>().map_err(de::Error::custom)?);
                        }
                        "height" => {
                            height = Some(value.parse::<u32>().map_err(de::Error::custom)?);
                        }
                        // ignore
                        "faces" => {}
                        "wallust" => {
                            wallust = Some(value);
                        }
                        _ => {
                            geometries.insert(key.to_string(), value);
                        }
                    }
                }

                let filename = filename.ok_or_else(|| de::Error::missing_field("filename"))?;
                let width = width.ok_or_else(|| de::Error::missing_field("width"))?;
                let height = height.ok_or_else(|| de::Error::missing_field("height"))?;
                let wallust = wallust.ok_or_else(|| de::Error::missing_field("wallust"))?;

                // geometries have no width and height, calculate from wall info
                Ok(WallInfo {
                    filename,
                    width,
                    height,
                    geometries,
                    wallust,
                })
            }
        }

        const FIELDS: &[&str] = &[
            "filename",
            "width",
            "height",
            "faces",
            "geometries",
            "wallust",
        ];
        deserializer.deserialize_struct("WallInfo", FIELDS, WallInfoVisitor)
    }
}

pub fn history() -> Vec<(PathBuf, chrono::DateTime<chrono::FixedOffset>)> {
    let Ok(history_csv) = std::fs::File::open(full_path("~/Pictures/wallpapers_history.csv"))
    else {
        return Vec::new();
    };

    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(false)
        .from_reader(std::io::BufReader::new(history_csv));

    rdr.records()
        .flatten()
        .filter_map(|row| {
            let (Some(fname), Some(dt_str)) = (row.get(0), row.get(1)) else {
                return None;
            };

            let path = dir().join(fname);
            if !path.exists() {
                return None;
            }

            chrono::DateTime::parse_from_rfc3339(dt_str)
                .ok()
                .map(|dt| (path, dt))
        })
        .sorted_by_key(|(_, dt)| *dt)
        .rev()
        .collect_vec()
}
