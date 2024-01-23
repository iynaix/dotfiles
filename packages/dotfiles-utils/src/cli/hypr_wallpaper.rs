use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs, cmd, full_path, monitor::Monitor, nixinfo::NixInfo, wallpaper, wallust,
    WAYBAR_CLASS,
};
use serde::Deserialize;
use std::{collections::HashMap, path::Path, process::Command};

#[derive(Debug, Default, Deserialize, Clone)]
pub struct Face {
    #[serde(rename = "0")]
    pub xmin: u32,
    #[serde(rename = "1")]
    pub xmax: u32,
    #[serde(rename = "2")]
    pub ymin: u32,
    #[serde(rename = "3")]
    pub ymax: u32,
}

#[derive(Debug, Default, Deserialize, Clone)]
pub struct WallustOptions {
    pub check_contrast: Option<bool>,
    pub filter: Option<String>,
    pub saturation: Option<i32>,
    pub threshold: Option<i32>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct WallInfo {
    pub faces: Vec<Face>,
    #[serde(rename = "1440x2560")]
    pub r1440x2560: String,
    #[serde(rename = "2256x1504")]
    pub r2256x1504: String,
    #[serde(rename = "3440x1440")]
    pub r3440x1440: String,
    #[serde(rename = "1920x1080")]
    pub r1920x1080: String,
    pub wallust: Option<WallustOptions>,
}

impl WallInfo {
    const fn get_geometry(&self, width: i32, height: i32) -> Option<&String> {
        match (width, height) {
            (1440, 2560) => Some(&self.r1440x2560),
            (2256, 1504) => Some(&self.r2256x1504),
            (3440, 1440) => Some(&self.r3440x1440),
            (1920, 1080) => Some(&self.r1920x1080),
            _ => None,
        }
    }
}

fn get_wallpaper_info(image: &String) -> Option<WallInfo> {
    let wallpapers_json = full_path("~/Pictures/Wallpapers/wallpapers.json");
    if !wallpapers_json.exists() {
        return None;
    }

    // convert image to path
    let image = Path::new(image);
    let fname = image
        .file_name()
        .expect("invalid image path")
        .to_str()
        .expect("could not convert image path to str");

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_json).expect("could not open wallpapers.json"),
    );
    let mut crops: HashMap<String, WallInfo> =
        serde_json::from_reader(reader).expect("could not parse wallpapers.json");
    crops.remove(fname)
}

fn swww_crop(swww_args: &[&str], image: &String, wall_info: &Option<WallInfo>) {
    let set_wallpapers = || {
        // write image path to ~/.cache/current_wallpaper
        std::fs::write(full_path("~/.cache/current_wallpaper"), image)
            .expect("failed to write ~/.cache/current_wallpaper");

        match wall_info {
            Some(info) => Monitor::monitors().iter().for_each(|m| {
                match info.get_geometry(m.width, m.height) {
                    Some(geometry) => {
                        // use custom swww-crop defined in wallpaper.nix
                        Command::new("swww-crop")
                            .arg(image)
                            .arg(geometry)
                            .arg(&m.name)
                            .args(swww_args)
                            .spawn()
                            .expect("failed to set wallpaper");
                    }
                    None => {
                        Command::new("swww")
                            .arg("img")
                            .args(swww_args)
                            .arg(image)
                            .spawn()
                            .expect("failed to execute process");
                    }
                }
            }),
            _ => {
                Command::new("swww")
                    .arg("img")
                    .args(swww_args)
                    .arg(image)
                    .spawn()
                    .expect("failed to execute process");
            }
        }
    };

    set_wallpapers();
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    let random_wallpaper = match args.image {
        Some(image) => std::fs::canonicalize(image)
            .expect("invalid image path")
            .to_str()
            .expect("could not convert image path to str")
            .to_string(),
        None => {
            if full_path("~/.cache/wallust/nix.json").exists() {
                wallpaper::random()
            } else {
                NixInfo::before().fallback
            }
        }
    };

    let wallpaper = if args.reload {
        wallpaper::current().unwrap_or(random_wallpaper)
    } else {
        random_wallpaper
    };

    let wallpaper_info = get_wallpaper_info(&wallpaper);

    // use colorscheme set from nix if available
    if let Some(cs) = NixInfo::before().colorscheme {
        wallust::apply_theme(cs.as_str());
    } else {
        let mut wallust_cmd = Command::new("wallust");

        // normalize the options for wallust
        if let Some(WallInfo {
            wallust: Some(opts),
            ..
        }) = &wallpaper_info
        {
            if opts.check_contrast == Some(true) {
                wallust_cmd.arg("--check-contrast");
            }
            if let Some(filter) = &opts.filter {
                wallust_cmd.arg("--filter");
                if matches!(
                    filter.as_str(),
                    // valid values for filter, ignore light values
                    "dark" | "dark16" | "harddark" | "harddark16" | "softdark" | "softdark16"
                ) {
                    wallust_cmd.arg(filter);
                }
            }
            if let Some(saturation) = opts.saturation {
                wallust_cmd.arg("--saturation").arg(saturation.to_string());
            }
            if let Some(threshold) = opts.threshold {
                wallust_cmd.arg("--threshold").arg(threshold.to_string());
            }
        }

        // finally run wallust
        wallust_cmd
            .arg(&wallpaper)
            .spawn()
            .expect("failed to execute process");
    }

    if cfg!(feature = "hyprland") {
        if args.reload {
            swww_crop(&[], &wallpaper, &wallpaper_info);
            cmd(["killall", "-SIGUSR2", WAYBAR_CLASS]);
        } else {
            swww_crop(
                &["--transition-type", &args.transition_type],
                &wallpaper,
                &wallpaper_info,
            );
        }
    }

    wallust::apply_colors();
}
