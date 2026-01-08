use common::wallpaper::{Geometry, WallInfo};
use fast_image_resize::{FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image};
use image::{ImageEncoder, ImageReader, codecs::png::PngEncoder};
use itertools::Itertools;
use wallpaper::write_wallpaper_history;

use crate::{cli::CropArgs, metadata::aspect_ratio};

/// parse an aspect ratio, e.g. 9x16
fn parse_aspect(aspect: &str) -> (u32, u32) {
    let aspect = aspect.split('x').flat_map(str::parse::<u32>).collect_vec();
    assert!(aspect.len() == 2, "invalid aspect ratio: {aspect:?}");
    (aspect[0], aspect[1])
}

fn crop_geometry(
    wall_info: &WallInfo,
    img_w: f64,
    img_h: f64,
    target_w: u32,
    taget_h: u32,
) -> Geometry {
    // predefined in image
    if let Some(geom) = wall_info.get_geometry(target_w, taget_h) {
        return geom;
    }

    let target_aspect = f64::from(target_w) / f64::from(taget_h);
    let current_aspect = img_w / img_h;

    // default crop from the center
    let default_crop = {
        let (crop_w, crop_h) = {
            if current_aspect > target_aspect {
                // Image is too wide: match height, reduce width
                (img_h * target_aspect, img_h)
            } else {
                // Image is too tall: match width, reduce height
                (img_w, img_w / target_aspect)
            }
        };

        Geometry {
            w: crop_w,
            h: crop_h,
            x: (img_w - crop_w) / 2.0,
            y: (img_h - crop_h) / 2.0,
        }
    };

    // get the closest aspect ratio to the image
    let Some((closest_w, closest_h)) = wall_info
        .geometries
        .keys()
        .min_by(|aspect1, aspect2| {
            let diff1 = (aspect_ratio(aspect1) - target_aspect).abs();
            let diff2 = (aspect_ratio(aspect2) - target_aspect).abs();

            // ignore if aspect ratio already exists in config
            diff1
                .partial_cmp(&diff2)
                .unwrap_or(std::cmp::Ordering::Equal)
        })
        .map(|aspect| parse_aspect(aspect))
    else {
        // no geometries
        return default_crop;
    };

    let closest = wall_info
        .get_geometry(closest_w, closest_h)
        .expect("failed to get closest geometry");

    // same width, translate y
    if (closest.w - default_crop.w).abs() < f64::EPSILON {
        let new_y = (closest.y + closest.h - default_crop.h) / 2.0;
        return Geometry {
            y: new_y.clamp(0.0, img_h - closest.h),
            ..closest
        };
    }

    // same height, translate x
    if (closest.h - default_crop.h).abs() < f64::EPSILON {
        let new_x = (closest.x + closest.w - default_crop.w) / 2.0;
        return Geometry {
            x: new_x.clamp(0.0, img_w - closest.w),
            ..closest
        };
    }

    // different direction, give up and just use center crop
    default_crop
}

/// uses crop info from wallpaper xmp metadata
pub fn crop(args: &CropArgs) {
    let (mon_w, mon_h) = parse_aspect(&args.size);
    let wall_info = WallInfo::new_from_file(&args.input);

    let img = ImageReader::open(&args.input)
        .expect("could not open image")
        .decode()
        .expect("could not decode image")
        .to_rgb8();

    let (img_w, img_h) = img.dimensions();
    let geom = crop_geometry(&wall_info, f64::from(img_w), f64::from(img_h), mon_w, mon_h);

    // convert to rgb8 pixel type
    let src = Image::from_vec_u8(img_w, img_h, img.into_raw(), PixelType::U8x3)
        .expect("Failed to create source image view");

    let mut dest = Image::new(mon_w, mon_h, PixelType::U8x3);
    Resizer::new()
        .resize(
            &src,
            &mut dest,
            &ResizeOptions::new()
                .resize_alg(ResizeAlg::Convolution(FilterType::Lanczos3))
                .use_alpha(false)
                .crop(geom.x, geom.y, geom.w, geom.h),
        )
        .expect("failed to resize image");

    let mut result_buf = std::io::BufWriter::new(
        std::fs::File::create(&args.output).expect("could not create file"),
    );

    PngEncoder::new(&mut result_buf)
        .write_image(dest.buffer(), mon_w, mon_h, image::ColorType::Rgb8.into())
        .expect("failed to save png");

    // save to history
    write_wallpaper_history(args.input.clone());
}
