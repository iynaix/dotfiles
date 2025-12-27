use common::wallpaper::WallInfo;
use fast_image_resize::{FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image};
use image::{ImageEncoder, ImageReader, codecs::jpeg::JpegEncoder};
use wallpaper::write_wallpaper_history;

use crate::cli::CropArgs;

/// uses crop info from wallpaper xmp metadata
pub fn crop(args: &CropArgs) {
    // parse size
    let size: Vec<_> = args.size.split('x').flat_map(str::parse::<u32>).collect();
    assert!(size.len() == 2, "invalid size: {:?}", args.size);
    let (mon_w, mon_h) = (size[0], size[1]);

    let wall_info = WallInfo::new_from_file(&args.input);

    let img = ImageReader::open(&args.input)
        .expect("could not open image")
        .decode()
        .expect("could not decode image")
        .to_rgb8();

    let (w, h, x, y) = wall_info.get_geometry(mon_w, mon_h).unwrap_or_else(|| {
        // TODO: get from closest available aspect ratio?

        let (w, h) = img.dimensions();
        let w = f64::from(w);
        let h = f64::from(h);

        let current_aspect = w / h;
        let target_aspect = f64::from(mon_w) / f64::from(mon_h);

        let (crop_w, crop_h) = if current_aspect > target_aspect {
            // Image is too wide: match height, reduce width
            (h * target_aspect, h)
        } else {
            // Image is too tall: match width, reduce height
            (w, w / target_aspect)
        };

        (crop_w, crop_h, (w - crop_w) / 2.0, (h - crop_h) / 2.0)
    });

    // convert to rgb8 pixel type
    let src = Image::from_vec_u8(img.width(), img.height(), img.into_raw(), PixelType::U8x3)
        .expect("Failed to create source image view");

    let mut dest = Image::new(mon_w, mon_h, PixelType::U8x3);
    Resizer::new()
        .resize(
            &src,
            &mut dest,
            &ResizeOptions::new()
                .resize_alg(ResizeAlg::Convolution(FilterType::Lanczos3))
                .use_alpha(false)
                .crop(x, y, w, h),
        )
        .expect("failed to resize image");

    let mut result_buf = std::io::BufWriter::new(
        std::fs::File::create(&args.output).expect("could not create file"),
    );

    JpegEncoder::new_with_quality(&mut result_buf, 95)
        .write_image(dest.buffer(), mon_w, mon_h, image::ColorType::Rgb8.into())
        .expect("failed to save jpeg");

    // save to history
    write_wallpaper_history(args.input.clone());
}
