use clap::{value_parser, Parser, Subcommand, ValueEnum};
use std::path::PathBuf;

// ------------------ HYPR MONITOR ------------------
#[derive(ValueEnum, Debug, Clone)]
pub enum MonitorExtend {
    Primary,
    Secondary,
}

#[derive(Parser, Debug)]
#[command(name = "hypr-monitors", about = "Re-arranges workspaces to monitor")]
/// Utilities for working with adding or removing monitors in hyprland
/// Without arguments, it redistributes the workspaces across all monitors
pub struct HyprMonitorArgs {
    #[arg(
        long,
        value_parser = value_parser!(MonitorExtend),
        help = "set new monitor(s) to be primary or secondary"
    )]
    pub extend: Option<MonitorExtend>,

    #[arg(long, name = "MONITOR", action, help = "mirrors the primary monitor")]
    pub mirror: Option<String>,

    // show rofi menu for selecting monitor
    #[arg(long, action, help = "show rofi menu for monitor options")]
    pub rofi: Option<String>,
}

// ------------------ HYPR SAME CLASS ------------------
#[derive(Subcommand, Debug)]
pub enum HyprSameClassDirection {
    Next,
    Prev,
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr-same-class",
    about = "Focus next / prev window of same class"
)]
pub struct HyprSameClassArgs {
    #[command(subcommand)]
    pub direction: HyprSameClassDirection,
}

// ------------------ HYPR WALLPAPER ------------------

#[derive(Parser, Debug)]
#[command(
    name = "hypr-wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
pub struct HyprWallpaperArgs {
    #[arg(long, action, help = "reload current wallpaper")]
    pub reload: bool,

    // optional image to use, uses a random one otherwise
    pub image_or_dir: Option<PathBuf>,
}

// ------------------ ROFI MPV ------------------

#[derive(Subcommand, Debug)]
pub enum RofiMpvMedia {
    Anime,
    TV,
}

#[derive(Parser, Debug)]
#[command(
    name = "rofi-media",
    about = "Plays the next episode of anime or tv shows"
)]
pub struct RofiMpvArgs {
    #[command(subcommand)]
    pub media: RofiMpvMedia,
}

// ------------------ SWWW CROP ------------------
#[derive(Parser, Debug)]
#[command(
    name = "swww-crop",
    about = "Applies image crops for wallpapers on each monitor"
)]
pub struct SwwwCropArgs {
    // optional image to use, uses a random one otherwise
    pub image: Option<PathBuf>,
}
