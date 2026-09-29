use crate::cli::MetadataArgs;
use color_eyre::eyre::Result;
use common::wallpaper::{self, WallInfo};

pub fn metadata(args: MetadataArgs) -> Result<()> {
    let image = args.file.unwrap_or(wallpaper::current()?.into());
    let info = WallInfo::from_path(&image)?;

    let (width, height) = image::image_dimensions(&image)?;
    println!("{} ({width}x{height})\n", image.display());

    let print_kv = |left: &str, right: &str| {
        println!("{left:15}: {right}");
    };

    if !info.faces.is_empty() {
        print_kv(
            "Faces",
            &info
                .faces
                .iter()
                .map(std::string::ToString::to_string)
                .collect::<Vec<_>>()
                .join(", "),
        );
    }

    println!("Crops");
    info.geometries.iter().for_each(|(aspect, geom)| {
        print_kv(&format!("    {aspect}"), geom);
    });

    if let Some(scale) = info.scale {
        println!("Scale: {scale}");
    }

    Ok(())
}
