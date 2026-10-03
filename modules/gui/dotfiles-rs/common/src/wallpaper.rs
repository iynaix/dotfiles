use color_eyre::eyre::{Result, eyre};
use execute::Execute;
use itertools::Itertools;
use xmpkit::{XmpFile, XmpValue};

use crate::{full_path, nixjson::NixJson};
use std::{
    collections::{HashMap, HashSet},
    path::{Path, PathBuf},
    process::Stdio,
};

pub fn dir() -> PathBuf {
    full_path("~/Pictures/Wallpapers")
}

pub fn current() -> Result<String> {
    let cmd = execute::command_args!("noctalia", "msg", "wallpaper-get")
        .stdout(Stdio::piped())
        .execute_output()?;

    Ok(String::from_utf8(cmd.stdout).map(|s| s.trim().to_string())?)
}

pub fn filter_images<P>(dir: P) -> impl Iterator<Item = String>
where
    P: AsRef<Path> + std::fmt::Debug,
{
    dir.as_ref()
        .read_dir()
        .unwrap_or_else(|_| panic!("could not read {dir:?}"))
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.is_file()
                && let Some(ext) = path.extension()
                && matches!(ext.to_str(), Some("jpg" | "jpeg" | "png" | "webp"))
            {
                return Some(path.to_str()?.to_string());
            }

            None
        })
}

/// sets the wallpaper for all monitors
pub fn set<P>(wallpaper: P) -> Result<()>
where
    P: AsRef<Path> + std::fmt::Debug,
{
    execute::command_args!("noctalia", "msg", "wallpaper-set")
        .arg(wallpaper.as_ref())
        .stdin(Stdio::null())
        .status()?;

    Ok(())
}

/// reloads the wallpaper
pub fn reload() -> Result<()> {
    // reload noctalia
    let child = execute::command_args!("noctalia-reload").spawn()?;
    drop(child); // don't wait

    Ok(())
}

pub fn random_from_dir<P>(dir: P) -> String
where
    P: AsRef<Path> + std::fmt::Debug,
{
    if !dir.as_ref().exists() {
        return NixJson::load().fallback_wallpaper;
    }

    let wallpapers = filter_images(dir).collect_vec();
    if wallpapers.is_empty() {
        NixJson::load().fallback_wallpaper
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
pub struct Geometry {
    pub w: f64,
    pub h: f64,
    pub x: f64,
    pub y: f64,
}

impl std::fmt::Display for Geometry {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}x{}+{}+{}", self.w, self.h, self.x, self.y)
    }
}

impl TryFrom<&str> for Geometry {
    type Error = Box<dyn std::error::Error>;

    fn try_from(s: &str) -> Result<Self, Self::Error> {
        let geometry = s
            .split(['x', '+'])
            .flat_map(str::parse::<f64>)
            .collect_vec();

        if geometry.len() != 4 {
            return Err("Invalid geometry format: expected wxh+x+y".into());
        }

        Ok(Self {
            w: geometry[0],
            h: geometry[1],
            x: geometry[2],
            y: geometry[3],
        })
    }
}

#[derive(Debug, Clone, Default)]
pub struct WallInfo {
    pub path: PathBuf,
    pub faces: Vec<Geometry>,
    pub geometries: HashMap<String, String>,
    pub scale: Option<u32>,
}

impl WallInfo {
    pub fn from_path<P>(img: P) -> Result<Self>
    where
        P: AsRef<Path> + std::fmt::Debug,
    {
        let wallfacer_ns = "http://example.com/wallfacer/";

        let mut fp = XmpFile::new();
        fp.open(&img)?;

        let mut ret = Self {
            path: img.as_ref().to_path_buf(),
            ..Default::default()
        };

        if let Some(xmp) = fp.get_xmp() {
            for prop in xmp.all_properties() {
                if prop.namespace_uri != wallfacer_ns {
                    continue;
                }

                if prop.name == "scale" {
                    ret.scale = prop.value.as_int().map(|scale| scale as u32);
                } else if let Some(aspect) = prop.name.strip_prefix("crop_")
                    && let XmpValue::String(geom) = prop.value
                {
                    ret.geometries.insert(aspect.to_string(), geom);
                } else if prop.name.starts_with("faces")
                    && let XmpValue::Array(faces) = prop.value
                {
                    ret.faces = faces
                        .iter()
                        .filter_map(|face| face.as_str()?.try_into().ok())
                        .collect();
                }
            }
        } else {
            return Err(eyre!("Unable to read xmp metadata for {img:?}"));
        }

        Ok(ret)
    }

    pub fn get_geometry(&self, width: u32, height: u32) -> Option<Geometry> {
        self.get_geometry_str(width, height).and_then(|geom| {
            let geometry = geom
                .split(['+', 'x'])
                .flat_map(str::parse::<f64>)
                .collect_vec();

            match geometry.as_slice() {
                &[w, h, x, y] => Some(Geometry { w, h, x, y }),
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

pub fn history() -> Result<Vec<(PathBuf, jiff::Zoned)>> {
    let Ok(history_csv) = std::fs::File::open(full_path("~/Pictures/wallpapers_history.csv"))
    else {
        return Ok(Vec::new());
    };

    let images: HashSet<String> = dir()
        .read_dir()?
        .flatten()
        .map(|entry| entry.file_name().to_string_lossy().to_string())
        .collect();

    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(false)
        .from_reader(std::io::BufReader::new(history_csv));

    let ret = rdr
        .records()
        .flatten()
        .filter_map(|row| {
            let (Some(fname), Some(dt_str)) = (row.get(0), row.get(1)) else {
                return None;
            };

            if !images.contains(fname) {
                return None;
            }

            jiff::fmt::strtime::parse("%Y-%m-%dT%H:%M:%S%:z", dt_str)
                .ok()?
                .to_zoned()
                .ok()
                .map(|dt| (dir().join(fname), dt))
        })
        .sorted_by_key(|(_, dt)| dt.clone())
        .rev()
        .collect_vec();

    Ok(ret)
}
