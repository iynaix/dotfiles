use crate::cli::MetadataArgs;
use common::wallpaper;

use rexiv2::Metadata;

pub fn aspect_ratio(aspect: &str) -> f64 {
    let aspect: Vec<_> = aspect.split('x').flat_map(str::parse::<f64>).collect();

    assert!(aspect.len() == 2, "invalid aspect ratio: {aspect:?}");

    aspect[0] / aspect[1]
}

pub fn metadata(args: MetadataArgs) {
    let image = args.file.unwrap_or_else(|| {
        wallpaper::current()
            .expect("failed to get current wallpaper")
            .into()
    });

    let meta = Metadata::new_from_path(&image).expect("could not init new metadata");

    let mut crops = Vec::new();
    let mut scale = 1;
    let mut wallust = String::new();
    let mut faces = String::new();

    for tag in meta.get_xmp_tags().expect("unable to read xmp tags") {
        match tag.as_str() {
            "Xmp.wallfacer.wallust" => {
                wallust = meta
                    .get_tag_string(&tag)
                    .expect("could not get wallust tag");
            }
            "Xmp.wallfacer.scale" => {
                scale = meta
                    .get_tag_string(&tag)
                    .expect("could not get scale tag")
                    .parse()
                    .unwrap_or_default();
            }
            "Xmp.wallfacer.faces" => {
                faces = meta
                    .get_tag_string(&tag)
                    .expect("could not get faces tag")
                    .replace(',', ", ");
            }
            _ if tag.starts_with("Xmp.wallfacer.crop.") => {
                let aspect = tag
                    .strip_prefix("Xmp.wallfacer.crop.")
                    .expect("could not strip crop prefix");
                let geom = meta.get_tag_string(&tag).expect("could not get crop tag");

                crops.push((aspect.to_string(), geom));
            }
            _ => {}
        }
    }

    crops.sort_by(|(aspect1, _), (aspect2, _)| {
        let aspect1 = aspect_ratio(aspect1);
        let aspect2 = aspect_ratio(aspect2);

        aspect1
            .partial_cmp(&aspect2)
            .expect("aspect ratios not comparable")
    });

    let print_kv = |left: &str, right: &str| {
        println!("{left:15}: {right}");
    };

    println!("{}\n", image.display());
    print_kv("Faces", &faces);
    println!("Crops");
    for (aspect, geom) in crops {
        print_kv(&format!("    {aspect}"), &geom);
    }
    println!("Scale: {scale}");
    print_kv("Wallust", &wallust);
}
