use rand::seq::SliceRandom;
use serde::{de, Deserialize, Deserializer};

use crate::{full_path, nixinfo::NixInfo};
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
        self.geometries.get(&format!("{width}x{height}"))
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
                let geometries = geometries
                    .iter()
                    .map(|(ratio, geom)| {
                        let parts: Vec<&str> = ratio.split('x').collect();
                        assert!(parts.len() == 2, "invalid aspect ratio: {ratio}");

                        let target_w = parts[0].parse::<u32>().expect("invalid aspect ratio width");
                        let target_h = parts[1]
                            .parse::<u32>()
                            .expect("invalid aspect ratio height");

                        // Calculate width and height that can be cropped while maintaining aspect ratio
                        let crop_w = std::cmp::min(width, height * target_w / target_h);
                        let crop_h = std::cmp::min(height, width * target_h / target_w);

                        // Choose the larger dimension to get the largest possible cropped rectangle
                        let (crop_w, crop_h) = if crop_w * target_h > crop_h * target_w {
                            (crop_w, crop_h)
                        } else {
                            (crop_h * target_w / target_h, crop_h)
                        };
                        (ratio.clone(), format!("{crop_w}x{crop_h}+{geom}"))
                    })
                    .collect();

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
