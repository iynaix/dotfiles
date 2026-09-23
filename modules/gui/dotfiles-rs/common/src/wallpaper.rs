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

pub fn current() -> Option<String> {
    let cmd = execute::command_args!("noctalia", "msg", "wallpaper-get")
        .stdout(Stdio::piped())
        .execute_output()
        .ok()?;

    String::from_utf8(cmd.stdout)
        .ok()
        .map(|s| s.trim().to_string())
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
    let wallpaper = wallpaper
        .as_ref()
        .to_str()
        .expect("could not convert wallpaper path to str")
        .to_string();

    execute::command_args!("noctalia", "msg", "wallpaper-set")
        .arg(&wallpaper)
        .spawn()
        .unwrap_or_else(|_| panic!("failed to set wallpaper: {wallpaper}"))
        .wait()
        .expect("failed to wait for noctalia wallpaper set");
}

/// reloads the wallpaper
pub fn reload() {
    // reload noctalia
    let child = execute::command_args!("noctalia-reload")
        .spawn()
        .expect("failed to reload noctalia");
    drop(child); // don't wait
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
}

impl WallInfo {
    pub fn new_from_file<P>(img: P) -> Self
    where
        P: AsRef<Path> + std::fmt::Debug,
    {
        let wallfacer_ns = "http://example.com/wallfacer/";

        let mut fp = XmpFile::new();
        fp.open(&img).expect("failed to open image");

        let mut ret = Self {
            path: img.as_ref().to_path_buf(),
            ..Default::default()
        };

        if let Some(xmp) = fp.get_xmp() {
            if let Some(XmpValue::Array(faces)) = xmp.get_property(wallfacer_ns, "faces") {
                ret.faces = faces
                    .iter()
                    .map(|face| {
                        face.as_str()
                            .expect("could not convert face to str")
                            .try_into()
                            .unwrap_or_else(|_| panic!("could not convert face {face} into string"))
                    })
                    .collect();
            }

            if let Some(XmpValue::Structure(crops)) = xmp.get_property("wallfacer", "crops") {
                ret.geometries = crops
                    .iter()
                    .map(|(aspect, geom)| {
                        let aspect = aspect
                            .strip_prefix(&format!("{wallfacer_ns}:"))
                            .expect("cannot strip prefix")
                            .to_string();

                        let geom = geom
                            .as_str()
                            .expect("could not convert crop to str")
                            .to_string();

                        (aspect, geom)
                    })
                    .collect();
            }
        } else {
            panic!("unable to read xmp metadata for {img:?}");
        }

        ret
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
