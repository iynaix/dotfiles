use crate::wallpaper::WallInfo;
use execute::Execute;
use fast_image_resize::{PixelType, ResizeOptions, Resizer, images::Image};
use image::codecs::webp::WebPEncoder;
use image::{ImageEncoder, ImageReader};
use rayon::prelude::*;
use serde::Deserialize;
use std::path::{Path, PathBuf};
use std::process::Stdio;

/// chooses a random transition
// taken from ZaneyOS: https://gitlab.com/Zaney/zaneyos/-/blob/main/config/scripts/wallsetter.nix
fn get_random_transition() -> Vec<String> {
    let transitions = [
        vec![
            "--transition-type",
            "wave",
            "--transition-angle",
            "120",
            "--transition-step",
            "30",
        ],
        vec![
            "--transition-type",
            "wipe",
            "--transition-angle",
            "30",
            "--transition-step",
            "30",
        ],
        vec!["--transition-type", "center", "--transition-step", "30"],
        vec![
            "--transition-type",
            "outer",
            "--transition-pos",
            "0.3,0.8",
            "--transition-step",
            "30",
        ],
        vec![
            "--transition-type",
            "wipe",
            "--transition-angle",
            "270",
            "--transition-step",
            "30",
        ],
    ];

    transitions[fastrand::usize(..transitions.len())]
        .iter()
        .map(std::string::ToString::to_string)
        .collect()
}

pub struct Swww {
    wall: PathBuf,
}

impl Swww {
    pub fn new<P>(wall: P) -> Self
    where
        P: AsRef<Path> + std::fmt::Debug,
    {
        Self {
            wall: wall.as_ref().to_path_buf(),
        }
    }

    // no crop info, just let swww crop the center
    fn mon_without_crop(&self, mon_name: &str, transition_args: &[String]) {
        execute::command_args!("swww", "img", "--outputs")
            .arg(mon_name)
            .args(transition_args)
            .arg(&self.wall)
            .execute()
            .expect("failed to set wallpaper");
    }

    // use crop info from wallpaper for swww
    fn mon_with_crop(
        &self,
        mon_name: &str,
        (mon_w, mon_h): (u32, u32),
        (w, h, x, y): (f64, f64, f64, f64),
        mon_scale: f64,
        transition_args: &[String],
    ) {
        let img = ImageReader::open(&self.wall)
            .expect("could not open image")
            .decode()
            .expect("could not decode image")
            .to_rgb8();

        // convert to rgb8 pixel type
        let src = Image::from_vec_u8(img.width(), img.height(), img.into_raw(), PixelType::U8x3)
            .expect("Failed to create source image view");

        let mut dest = Image::new(mon_w, mon_h, PixelType::U8x3);
        Resizer::new()
            .resize(
                &src,
                &mut dest,
                &ResizeOptions::new().use_alpha(false).crop(x, y, w, h),
            )
            .expect("failed to resize image");

        let fname = format!("/tmp/swww__{mon_name}.webp");
        let mut result_buf =
            std::io::BufWriter::new(std::fs::File::create(&fname).expect("could not create file"));

        WebPEncoder::new_lossless(&mut result_buf)
            .write_image(dest.buffer(), mon_w, mon_h, image::ColorType::Rgb8.into())
            .expect("failed to savea webp image for swww");

        // HACK: get swww to update the scale, or it thinks it's still 1.0???
        if (mon_scale - 1.0).abs() > f64::EPSILON {
            execute::command_args!("swww", "clear", "--outputs")
                .arg(mon_name)
                .spawn()
                .ok();
        }

        execute::command_args!("swww", "img", "--no-resize")
            .arg("--outputs")
            .arg(mon_name)
            .args(transition_args)
            .arg(&fname)
            .spawn()
            .expect("failed to execute swww")
            .wait()
            .expect("failed to wait for swww");

        #[cfg(feature = "niri")]
        {
            const BLUR_STRENGTH: f32 = 10.0;
            let blurred_fname = format!("/tmp/swww__{mon_name}_blurred.webp");
            let img = ImageReader::open(&fname)
                .expect("could not open image")
                .decode()
                .expect("could not decode image")
                .to_rgb8();

            let blurred_img = image::imageops::fast_blur(&img, BLUR_STRENGTH);
            blurred_img
                .save(&blurred_fname)
                .expect("failed to save blurred webp image for backdrop");

            // set overview backdrop with blurred wallpaper via swaybg
            // runs in the background and doesn't yield control back to the user, so don't wait
            execute::command_args!("swww", "img", "--no-resize", "--namespace", "backdrop")
                .arg("--outputs")
                .arg(mon_name)
                .arg(&blurred_fname)
                .spawn()
                .expect("failed to execute swww for backdrop")
                .wait()
                .expect("failed to wait for swww for backdrop");
        }
    }

    pub fn run(&self, wall_info: &WallInfo, transition: Option<&str>) {
        #[derive(Debug, Deserialize)]
        #[serde(rename_all = "camelCase")]
        pub struct WlrMonitor {
            pub enabled: bool,
            pub name: String,
            pub modes: Vec<WlrMode>,
            pub transform: String,
            pub scale: f64,
        }

        #[derive(Debug, Deserialize)]
        #[serde(rename_all = "camelCase")]
        pub struct WlrMode {
            pub width: u32,
            pub height: u32,
            pub current: bool,
        }

        let transition_args = transition.as_ref().map_or_else(get_random_transition, |t| {
            vec!["--transition-type".to_string(), (*t).to_string()]
        });

        // set the wallpaper per monitor, use wlr-randr so it is wm agnostic
        let wlr_cmd = execute::command_args!("wlr-randr", "--json")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("failed to run wlr-randr");
        let wlr_json = String::from_utf8(wlr_cmd.stdout).expect("invalid utf8 from wlr-randr");
        let monitors: Vec<WlrMonitor> =
            serde_json::from_str(&wlr_json).expect("failed to parse json");

        monitors
            .par_iter()
            .filter_map(|mon| {
                if !mon.enabled {
                    return None;
                }

                // get current mode for each monitor
                mon.modes
                    .iter()
                    .find(|mode| mode.current)
                    .map(|mode| (mon, mode))
            })
            .for_each(|(mon, mode)| {
                let (mon_w, mon_h) =
                    if mon.transform.contains("90") || mon.transform.contains("270") {
                        (mode.height, mode.width)
                    } else {
                        (mode.width, mode.height)
                    };

                match wall_info.get_geometry(mon_w, mon_h) {
                    Some(geom) => self.mon_with_crop(
                        &mon.name,
                        (mon_w, mon_h),
                        geom,
                        mon.scale,
                        &transition_args,
                    ),
                    None => self.mon_without_crop(&mon.name, &transition_args),
                }
            });
    }
}
