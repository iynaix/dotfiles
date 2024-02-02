use clap::{builder::PossibleValuesParser, Parser, Subcommand};
use std::path::PathBuf;

// ------------------ HYPR MONITOR ------------------
#[derive(Parser, Debug)]
#[command(name = "hypr-monitors", about = "Re-arranges workspaces to monitor")]
pub struct HyprMonitorArgs {
    #[arg(
        long,
        default_value = "primary",
        value_name = "EXTEND",
        value_parser = PossibleValuesParser::new([
            "primary",
            "secondary",
        ]),
        help = "set new display(s) to be primary or secondary"
    )]
    pub extend: Option<String>,
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

    #[arg(
        long,
        value_name = "TRANSITION",
        value_parser = PossibleValuesParser::new([
            "simple",
            "fade",
            "left",
            "right",
            "top",
            "bottom",
            "wipe",
            "wave",
            "grow",
            "center",
            "any",
            "random",
            "outer",
        ]),
        default_value = "random",
        help = "transition type for swww"
    )]
    pub transition_type: String,

    // optional image to use, uses a random one otherwise
    pub image: Option<PathBuf>,
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

// ------------------ WFETCH ------------------

#[allow(clippy::struct_excessive_bools)]
#[derive(Parser, Debug)]
#[command(name = "wfetch", about = "iynaix's custom fetch")]
pub struct WaifuFetchArgs {
    #[arg(long, action, help = "show hollow NixOS logo")]
    pub hollow: bool,

    #[cfg(feature = "wfetch-waifu")]
    #[arg(long, action, help = "show waifu NixOS logo")]
    pub waifu: bool,

    #[arg(
        long,
        num_args = 0..=1,
        default_missing_value = "",
        action, help = "show section of wallpaper",
    )]
    pub wallpaper: Option<String>,

    #[arg(
        long,
        num_args = 0..=1,
        default_missing_value = "",
        action, help = "show section of wallpaper in ascii",
    )]
    pub wallpaper_ascii: Option<String>,

    #[arg(long, action, help = "show challenge progress")]
    pub challenge: bool,

    #[arg(
        long,
        action,
        default_value = "1675821503",
        help = "start of the challenge as a UNIX timestamp in seconds"
    )]
    pub challenge_timestamp: i32,

    #[arg(
        long,
        action,
        default_value = "10",
        help = "duration of challenge in years"
    )]
    pub challenge_years: u32,

    #[arg(
        long,
        action,
        default_value = "0",
        help = "duration of challenge in months"
    )]
    pub challenge_months: u32,

    #[arg(long, action, help = "do not listen for SIGUSR2")]
    pub exit: bool,

    #[arg(long, action, help = "do not show colored keys")]
    pub no_color_keys: bool,

    #[arg(long, action, help = "image size in pixels")]
    pub image_size: Option<i32>,

    #[arg(long, action, default_value = "70", help = "ascii size in characters")]
    pub ascii_size: i32,
}
