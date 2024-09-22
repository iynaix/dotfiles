use crate::{vertical_dimensions, wallpaper::WallInfo};
use execute::Execute;
use fast_image_resize::{images::Image, PixelType, ResizeOptions, Resizer};
use hyprland::{
    data::{Monitor, Monitors},
    shared::{HyprData, HyprDataVec},
};
use image::codecs::webp::WebPEncoder;
use image::{ImageEncoder, ImageReader};
use rand::seq::SliceRandom;
use rayon::prelude::*;

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

    transitions
        .choose(&mut rand::thread_rng())
        .expect("could not choose transition")
        .iter()
        .map(std::string::ToString::to_string)
        .collect()
}

pub struct Swww {
    wall: String,
}

impl Swww {
    pub fn new(wall: &str) -> Self {
        Self {
            wall: wall.to_string(),
        }
    }

    fn no_crop(&self, transition_args: &[String]) {
        execute::command_args!("swww", "img")
            .args(transition_args)
            .arg(&self.wall)
            .execute()
            .expect("failed to set wallpaper");
    }

    fn with_crop(&self, mon: &Monitor, wall_info: &WallInfo, transition_args: &[String]) {
        let img = ImageReader::open(&self.wall)
            .expect("could not open image")
            .decode()
            .expect("could not decode image");

        let (mon_width, mon_height) = vertical_dimensions(mon);

        let dimensions = format!("{mon_width}x{mon_height}");

        let Some((w, h, x, y)) = wall_info.get_geometry(mon_width, mon_height) else {
            panic!("unable to get geometry for {}: {}", mon.name, dimensions);
        };

        #[allow(clippy::cast_sign_loss)]
        let mut dest = Image::new(mon_width as u32, mon_height as u32, PixelType::U8x3);

        Resizer::new()
            .resize(
                &img,
                &mut dest,
                &ResizeOptions::new().use_alpha(false).crop(x, y, w, h),
            )
            .expect("failed to resize image");

        let fname = format!("/tmp/swww__{}.webp", mon.name);
        let mut result_buf =
            std::io::BufWriter::new(std::fs::File::create(&fname).expect("could not create file"));

        #[allow(clippy::cast_sign_loss)]
        WebPEncoder::new_lossless(&mut result_buf)
            .write_image(
                dest.buffer(),
                mon_width as u32,
                mon_height as u32,
                image::ColorType::Rgb8.into(),
            )
            .expect("failed to write webp for swww");

        execute::command_args!("swww", "img", "--no-resize")
            .arg("--outputs")
            .arg(&mon.name)
            .args(transition_args)
            .arg(&fname)
            .spawn()
            .expect("failed to execute swww");
    }

    pub fn run(&self, wall_info: Option<WallInfo>, transition: &Option<String>) {
        let transition_args = transition.as_ref().map_or_else(get_random_transition, |t| {
            vec!["--transition-type".to_string(), t.to_string()]
        });

        // get the WallInfo for the image if it exists
        let Some(wall_info) = wall_info else {
            self.no_crop(&transition_args);
            return;
        };

        // set the wallpaper per monitor
        let monitors = Monitors::get().expect("could not get monitors").to_vec();

        // bail if any monitor doesn't have geometry info
        if monitors.iter().any(|m| {
            let (mw, mh) = vertical_dimensions(m);
            wall_info.get_geometry_str(mw, mh).is_none()
        }) {
            self.no_crop(&transition_args);
            return;
        }

        monitors
            .par_iter()
            .for_each(|mon| self.with_crop(mon, &wall_info, &transition_args));
    }
}
