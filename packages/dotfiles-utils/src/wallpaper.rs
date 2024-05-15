use rand::seq::SliceRandom;
use serde::{de, Deserialize, Deserializer};

use crate::{full_path, nixinfo::NixInfo};
use std::{collections::HashMap, fs, path::PathBuf};

pub fn dir() -> PathBuf {
    full_path("~/Pictures/Wallpapers")
}

pub fn current() -> Option<String> {
    let curr = NixInfo::after().wallpaper;

    let wallpaper = {
        if curr == "./foo/bar.text" {
            fs::read_to_string(
                dirs::runtime_dir()
                    .expect("could not get $XDG_RUNTIME_DIR")
                    .join("current_wallpaper"),
            )
            .ok()
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

fn filter_images<P>(dir: P) -> impl Iterator<Item = String>
where
    P: AsRef<std::path::Path> + std::fmt::Debug,
{
    dir.as_ref()
        .read_dir()
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

pub fn random_from_dir<P>(dir: P) -> String
where
    P: AsRef<std::path::Path> + std::fmt::Debug,
{
    filter_images(dir)
        .collect::<Vec<_>>()
        .choose(&mut rand::thread_rng())
        // use fallback image if not available
        .unwrap_or(&NixInfo::before().fallback)
        .to_string()
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
    pub fn get_geometry(&self, width: i32, height: i32) -> Option<&String> {
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
