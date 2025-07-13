use crate::wallpaper::WallInfo;
use execute::Execute;
use fast_image_resize::{PixelType, ResizeOptions, Resizer, images::Image};
use image::codecs::webp::WebPEncoder;
use image::{ImageEncoder, ImageReader};
use rayon::prelude::*;
use std::path::{Path, PathBuf};

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
        mon_width: u32,
        mon_height: u32,
        mon_scale: f64,
        wall_info: &WallInfo,
        transition_args: &[String],
    ) {
        let img = ImageReader::open(&self.wall)
            .expect("could not open image")
            .decode()
            .expect("could not decode image")
            .to_rgb8();

        let Some((w, h, x, y)) = wall_info.get_geometry(mon_width, mon_height) else {
            panic!("unable to get geometry for {mon_name}: {mon_width}x{mon_height}",);
        };

        // convert to rgb8 pixel type
        let src = Image::from_vec_u8(img.width(), img.height(), img.into_raw(), PixelType::U8x3)
            .expect("Failed to create source image view");

        #[allow(clippy::cast_sign_loss)]
        let mut dest = Image::new(mon_width, mon_height, PixelType::U8x3);

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

        #[allow(clippy::cast_sign_loss)]
        WebPEncoder::new_lossless(&mut result_buf)
            .write_image(
                dest.buffer(),
                mon_width,
                mon_height,
                image::ColorType::Rgb8.into(),
            )
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
        let transition_args = transition.as_ref().map_or_else(get_random_transition, |t| {
            vec!["--transition-type".to_string(), (*t).to_string()]
        });

        // set the wallpaper per monitor
        #[cfg(feature = "hyprland")]
        {
            use crate::vertical_dimensions;
            use hyprland::shared::{HyprData, HyprDataVec};
            let monitors = hyprland::data::Monitors::get()
                .expect("could not get monitors")
                .to_vec();

            monitors.par_iter().for_each(|mon| {
                let (mw, mh) = vertical_dimensions(mon);

                match wall_info.get_geometry_str(mw, mh) {
                    Some(_) => self.mon_with_crop(
                        &mon.name,
                        mw,
                        mh,
                        f64::from(mon.scale),
                        wall_info,
                        &transition_args,
                    ),
                    None => self.mon_without_crop(&mon.name, &transition_args),
                }
            });
        }

        #[cfg(feature = "niri")]
        {
            use niri_ipc::{Request, Response, socket::Socket};

            let Ok(Response::Outputs(monitors)) = Socket::connect()
                .expect("failed to connect to niri socket")
                .send(Request::Outputs)
                .expect("failed to send Outputs request to niri")
            else {
                panic!("unexpected response from niri, should be Outputs");
            };

            monitors
                .par_iter()
                // ignore disabled monitors
                .for_each(|(_, mon)| match mon.logical {
                    None => self.mon_without_crop(&mon.name, &transition_args),
                    Some(logical) => {
                        #[allow(clippy::cast_possible_truncation)]
                        #[allow(clippy::cast_sign_loss)]
                        let (mw, mh) = if (logical.scale - 1.0).abs() < f64::EPSILON {
                            (logical.width, logical.height)
                        } else {
                            (
                                (f64::from(logical.width) * logical.scale) as u32,
                                (f64::from(logical.height) * logical.scale) as u32,
                            )
                        };

                        self.mon_with_crop(
                            &mon.name,
                            mw,
                            mh,
                            logical.scale,
                            wall_info,
                            &transition_args,
                        );
                    }
                });
        }
    }
}
