use clap::{builder::PossibleValuesParser, Parser, Subcommand};
use std::path::PathBuf;

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
        action,
        help = "do not use wallust to generate colorschemes for programs"
    )]
    pub no_wallust: bool,

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

    #[arg(
        long,
        value_name = "FILTER",
        value_parser = PossibleValuesParser::new([
            // ignore non 16 colors colorschemes
            "dark16",
            "hard-dark",
            "light16",
            "soft-light",
            "soft-dark", // available via dev branch
        ]),
        help = "filter type for swww"
    )]
    pub filter: Option<String>,

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

// ------------------ WAIFUFETCH ------------------

#[derive(Parser, Debug)]
#[command(name = "waifufetch", about = "Neofetch, but more waifu")]
pub struct WaifuFetchArgs {
    #[arg(long, action, help = "prints path to generated image")]
    pub image: bool,
}
