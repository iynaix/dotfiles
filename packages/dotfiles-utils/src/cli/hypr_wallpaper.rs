use clap::Parser;
use dotfiles_utils::{
    cli::HyprWallpaperArgs, cmd, cmd_output, full_path, monitor::Monitor, nixinfo::NixInfo,
    wallpaper, wallust, CmdOutput,
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

#[derive(Debug, Deserialize, Clone)]
pub struct WallInfo {
    pub filter: String,
    pub faces: Vec<Face>,
    #[serde(rename = "1440x2560")]
    pub r1440x2560: String,
    #[serde(rename = "2256x1504")]
    pub r2256x1504: String,
    #[serde(rename = "3440x1440")]
    pub r3440x1440: String,
    #[serde(rename = "1920x1080")]
    pub r1920x1080: String,
}

impl WallInfo {
    fn get_geometry(&self, width: i32, height: i32) -> Option<&String> {
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
        .unwrap();

    let reader = std::io::BufReader::new(std::fs::File::open(wallpapers_json).unwrap());
    let mut crops: HashMap<String, WallInfo> = serde_json::from_reader(reader).unwrap();
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

    let is_daemon_running = !cmd_output(["swww", "query"], CmdOutput::Stderr)
        .first()
        .unwrap_or(&"".to_string())
        .starts_with("Error");

    if is_daemon_running {
        set_wallpapers();
    } else {
        // FIXME: weird race condition with swww init, need to sleep for a second
        // https://github.com/Horus645/swww/issues/144

        // sleep for a second
        std::thread::sleep(std::time::Duration::from_secs(1));

        let swww_init = Command::new("swww")
            .arg("init")
            .status()
            .expect("failed to execute swww init");

        // equivalent of bash &&
        if swww_init.success() {
            set_wallpapers();
        }
    }
}

fn main() {
    let args = HyprWallpaperArgs::parse();

    let random_wallpaper = match args.image {
        Some(image) => std::fs::canonicalize(image)
            .unwrap()
            .to_str()
            .unwrap()
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
    // prefer provided command line flag, then wallpaper info value, then "dark16"
    let filter_type = args.filter.unwrap_or(
        wallpaper_info
            .clone()
            .map_or("dark16".to_string(), |info| info.filter.clone()),
    );

    // use colorscheme set from nix if available
    match NixInfo::before().colorscheme {
        Some(cs) => wallust::apply_theme(cs),
        None => cmd(["wallust", "--filter", &filter_type, &wallpaper]),
    }

    if cfg!(feature = "hyprland") {
        if args.reload {
            swww_crop(&[], &wallpaper, &wallpaper_info);
            cmd(["killall", "-SIGUSR2", ".waybar-wrapped"])
        } else {
            swww_crop(
                &["--transition-type", &args.transition_type],
                &wallpaper,
                &wallpaper_info,
            );
        }
    }

    wallpaper::wallust_apply_colors();
}
