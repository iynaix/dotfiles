use crate::cli::MetadataArgs;
use common::wallpaper;

use xmpkit::{XmpFile, XmpValue};

pub fn aspect_ratio(aspect: &str) -> f64 {
    let aspect: Vec<_> = aspect.split('x').flat_map(str::parse::<f64>).collect();

    assert!(aspect.len() == 2, "invalid aspect ratio: {aspect:?}");

    aspect[0] / aspect[1]
}

pub fn metadata(args: MetadataArgs) {
    let wallfacer_ns = "http://example.com/wallfacer/";

    let image = args.file.unwrap_or_else(|| {
        wallpaper::current()
            .expect("failed to get current wallpaper")
            .into()
    });

    let (width, height) = image::image_dimensions(&image).expect("could not get image dimensions");
    println!("{} ({width}x{height})\n", image.display());

    let mut fp = XmpFile::new();
    fp.open(&image).expect("failed to open image");

    let print_kv = |left: &str, right: &str| {
        println!("{left:15}: {right}");
    };

    if let Some(xmp) = fp.get_xmp() {
        if let Some(XmpValue::Array(faces)) = xmp.get_property(wallfacer_ns, "faces") {
            if !faces.is_empty() {
                print_kv(
                    "Faces",
                    &faces
                        .iter()
                        .map(|face| face.as_str().expect("could not convert face to str"))
                        .collect::<Vec<_>>()
                        .join(", "),
                );
            }
        }

        println!("Crops");
        if let Some(XmpValue::Structure(crops)) = xmp.get_property(wallfacer_ns, "crops") {
            crops.iter().for_each(|(aspect, geom)| {
                let aspect = aspect
                    .as_str()
                    .strip_prefix(&format!("{wallfacer_ns}:"))
                    .expect("cannot strip prefix");

                let geom = geom.as_str().expect("unable to convert crop to str");

                print_kv(&format!("    {aspect}"), geom);
            });
        }

        if let Some(XmpValue::String(scale)) = xmp.get_property(wallfacer_ns, "scale") {
            println!("Scale: {scale}");
        }
    }
}
