use regex::RegexBuilder;
use rexiv2::Metadata;
use serde::Deserialize;
use std::path::Path;

use crate::cli::{Colorspace, ColorspaceArgs};

impl std::fmt::Display for Colorspace {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", format!("{self:?}").to_lowercase())
    }
}

impl std::str::FromStr for Colorspace {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "lab" => Ok(Self::Lab),
            "labmixed" => Ok(Self::LabMixed),
            "lch" => Ok(Self::Lch),
            "lchmixed" => Ok(Self::LchMixed),
            "lchansi" => Ok(Self::LchAnsi),
            _ => Err(format!("Unknown colorspace: {s}")),
        }
    }
}

#[derive(Debug, Deserialize)]
struct WallustConfig {
    color_space: Colorspace,
}

fn get_wallust_config_colorspace() -> Result<Colorspace, Box<dyn std::error::Error>> {
    let wallust_toml = dirs::config_dir()
        .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::NotFound, "config dir not found"))?
        .join("wallust/wallust.toml");

    let content = std::fs::read_to_string(&wallust_toml)?;
    let toml_content: WallustConfig = toml::from_str(&content)?;

    Ok(toml_content.color_space)
}

fn new_wallust_tag(raw_tag: &str, colorspace_arg: Option<Colorspace>) -> String {
    let colorspace_re = RegexBuilder::new(r"\b(lab|labmixed|lch|lchmixed|lchansi)\b")
        .case_insensitive(true)
        .build()
        .expect("could not compile regex");
    let re_matches = colorspace_re.captures(raw_tag);
    let tag_colorspace = re_matches.as_ref().and_then(|m| m[1].parse().ok());

    // toggle the colorspace: labmixed -> lchmixed -> lab -> lch -> labmixed
    let next_colorspace = |c: Colorspace| match c {
        Colorspace::LabMixed => Colorspace::LchMixed,
        Colorspace::LchMixed => Colorspace::Lch,
        Colorspace::Lch => Colorspace::Lab,
        _ => Colorspace::LabMixed,
    };

    // use the colorspace arg if provided
    let final_colorspace = colorspace_arg.unwrap_or_else(|| {
        next_colorspace(
            tag_colorspace.unwrap_or_else(|| get_wallust_config_colorspace().unwrap_or_default()),
        )
    });

    re_matches.map_or_else(
        || {
            format!("{raw_tag} --colorspace {final_colorspace}")
                .trim()
                .to_string()
        },
        |_| {
            colorspace_re
                .replace_all(raw_tag, final_colorspace.to_string())
                .to_string()
        },
    )
}

fn update_image_colorspace(image: &Path, meta: &Metadata, wallust_tag: &str) -> rexiv2::Result<()> {
    let prev_modified = std::fs::metadata(image)
        .and_then(|metadata| metadata.modified())
        .ok();

    meta.set_tag_string("Xmp.wallfacer.wallust", wallust_tag)?;
    meta.save_to_file(image)?;

    // reset the modified time to maintain sort order
    if let Some(prev_modified) = prev_modified {
        std::fs::OpenOptions::new()
            .write(true)
            .open(image)
            .and_then(|f| f.set_modified(prev_modified))
            .ok();
    }

    Ok(())
}

pub fn toggle(args: ColorspaceArgs) {
    let mut colorspace_arg = args.colorspace;
    let image = args.file.map_or_else(
        || {
            crate::wallpaper::current()
                .expect("failed to get current wallpaper")
                .into()
        },
        |img| {
            let img_str = img.to_string_lossy().to_lowercase();
            let img_str = img_str.as_str();
            if matches!(img_str, "lab" | "labmixed" | "lch" | "lchmixed" | "lchansi") {
                // use the colorspace arg if provided
                colorspace_arg = img_str.parse().ok();

                return crate::wallpaper::current()
                    .expect("failed to get current wallpaper")
                    .into();
            }
            img
        },
    );

    // read wallust config from image
    let meta = Metadata::new_from_path(&image)
        .unwrap_or_else(|_| panic!("failed to read metadata from {}", image.display()));

    let raw_tag = meta
        .get_tag_string("Xmp.wallfacer.wallust")
        .unwrap_or_default();

    let updated_tag = new_wallust_tag(&raw_tag, colorspace_arg);
    println!("Updated tag: \"{updated_tag}\"");

    // save the file
    update_image_colorspace(&image, &meta, &updated_tag)
        .expect("failed to update image wallust tag");

    // reload the wallpaper
    common::wallpaper::set(&image, None);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_wallust_tag() {
        for (tag, expected) in [
            ("", "--colorspace labmixed"), // default is lab, so first toggle is labmixed
            ("--colorspace labmixed", "--colorspace lchmixed"),
            ("--colorspace lchmixed", "--colorspace lch"),
            ("--colorspace lch", "--colorspace lab"),
            ("--colorspace lab", "--colorspace labmixed"),
            (
                "-b full --colorspace labmixed --palette harddark16",
                "-b full --colorspace lchmixed --palette harddark16",
            ),
        ] {
            assert_eq!(new_wallust_tag(tag, None), expected);
        }
    }
}
