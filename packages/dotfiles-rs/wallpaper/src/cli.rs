use clap::{ArgGroup, Args, Parser, Subcommand, ValueEnum};
use serde::Deserialize;
use std::path::PathBuf;

#[allow(clippy::module_name_repetitions)]
#[derive(Args, Debug, PartialEq, Eq)]
pub struct BackupArgs {
    #[arg(name = "PATH", help = "Path to backup wallpapers to")]
    pub target: Option<PathBuf>,
}

#[derive(Args, Debug, PartialEq, Eq)]
pub struct RemoteArgs {
    #[arg(name = "REMOTE", help = "Hostname of remote machine")]
    pub hostname: Option<String>,
}

#[allow(clippy::module_name_repetitions)]
#[derive(Args, Debug, PartialEq, Eq)]
pub struct SearchArgs {
    #[arg(
        short,
        long,
        name = "TOP",
        default_value = "50",
        help = "Number of top results to display"
    )]
    pub top: u32,

    #[arg(name = "QUERY", help = "Search query")]
    pub query: String,
}

#[derive(Args, Debug, PartialEq, Eq)]
pub struct EditArgs {
    #[arg(
        name = "IMAGE",
        help = "Wallpaper to edit, defaults to current wallpaper"
    )]
    pub file: Option<PathBuf>,
}

#[derive(Args, Debug, PartialEq, Eq)]
pub struct AddArgs {
    #[arg(raw = true, hide = true, required = false, last = false)]
    pub rest: Vec<String>,

    #[arg(
        name = "IMAGES",
        help = "Directories or images to add, defaults to wallpapers_in",
        last = true
    )]
    pub image_or_dir: Option<PathBuf>,
}

#[derive(Debug, Clone, Default, ValueEnum, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Colorspace {
    #[default]
    #[clap(name = "lab")]
    Lab,
    #[clap(name = "labmixed")]
    LabMixed,
    #[clap(name = "lch")]
    Lch,
    #[clap(name = "lchmixed")]
    LchMixed,
    #[clap(name = "lchansi")]
    LchAnsi,
}

#[allow(clippy::module_name_repetitions)]
#[derive(Args, Debug, PartialEq, Eq)]
pub struct ColorspaceArgs {
    #[arg(short, long, help = "Colorspace to use")]
    pub colorspace: Option<Colorspace>,

    #[arg(
        name = "COLORSPACE_OR_IMAGE",
        help = "Wallpaper to edit, defaults to current wallpaper"
    )]
    pub file: Option<PathBuf>,
}

#[derive(Args, Debug, PartialEq, Eq)]
pub struct MetadataArgs {
    #[arg(
        name = "IMAGE",
        help = "Image to display metadata for, defaults to current wallpaper"
    )]
    pub file: Option<PathBuf>,
}

// utilities for generating shell completions
#[derive(Subcommand, ValueEnum, Debug, Clone, PartialEq, Eq)]
pub enum ShellCompletion {
    Bash,
    Zsh,
    Fish,
}

#[derive(Args, Debug, PartialEq, Eq)]
pub struct GenerateArgs {
    #[arg(value_enum, help = "Type of shell completion to generate")]
    pub shell: ShellCompletion,
}

#[derive(Subcommand, Debug, PartialEq, Eq)]
pub enum WallpaperSubcommand {
    #[command(name = "generate", about = "Generate shell completions", hide = true)]
    Generate(GenerateArgs),

    #[command(name = "current", about = "Prints the path of the current wallpaper")]
    Current,

    #[command(name = "rm", about = "Deletes the current wallpaper", visible_aliases = ["remove", "delete", "yeet"])]
    Rm,

    #[command(name = "reload", about = "Reloads the current wallpaper", visible_aliases = ["refresh"])]
    Reload,

    #[command(name = "history", about = "Show wallpaper history selector with pqiv")]
    History,

    #[command(
        name = "rofi",
        visible_alias = "pqiv",
        about = "Show wallpaper selector with pqiv"
    )]
    Rofi,

    #[cfg(feature = "dedupe")]
    #[command(
        name = "dedupe",
        visible_aliases = ["czkawka", "unique", "uniq"],
        about = "Runs czkawka to show duplicate wallpapers"
    )]
    Dedupe,

    #[cfg(feature = "wallfacer")]
    #[command(
        name = "edit",
        visible_alias = "recrop",
        about = "Edit and reload the current wallpaper with wallfacer"
    )]
    Edit(EditArgs),

    #[cfg(feature = "wallfacer")]
    #[command(
        name = "add",
        about = "Processes wallpapers with upscaling and vertical crop"
    )]
    Add(AddArgs),

    #[cfg(feature = "rclip")]
    #[command(
        name = "search",
        visible_aliases = ["rg", "grep", "find", "rclip"],
        about = "Search for wallpapers using rclip"
    )]
    Search(SearchArgs),

    #[command(name = "backup", about = "Backup wallpapers to secondary location")]
    Backup(BackupArgs),

    #[command(
        name = "remote",
        visible_alias = "sync",
        about = "Sync wallpapers to another machine"
    )]
    Remote(RemoteArgs),

    #[command(
        name = "colorspace",
        visible_aliases = ["cs", "toggle", "cycle"],
        about = "Toggles and saves the colorspace for wallust"
    )]
    Colorspace(ColorspaceArgs),

    #[command(
        name = "metadata",
        about = "Prints metadata for the current wallpaper / image"
    )]
    Metadata(MetadataArgs),
}

#[allow(clippy::struct_excessive_bools)]
#[derive(Parser, Debug)]
#[command(
    name = "wallpaper",
    infer_subcommands = true,
    about = format!("Changes the wallpaper and updates the colorscheme for {}",
        if cfg!(feature = "hyprland") {
            "hyprland"
        } else if cfg!(feature = "niri") {
            "niri"
        } else if cfg!(feature = "mango") {
            "mango"
        } else {
            panic!("no wm feature enabled")
        }
)
)]
#[command(group(
    ArgGroup::new("exclusive_group")
        .args(&["reload", "image_or_dir"])
        .multiple(false)
))]
pub struct WallpaperArgs {
    #[command(subcommand)]
    pub command: Option<WallpaperSubcommand>,

    #[arg(long, action, help = "Reload current wallpaper")]
    pub reload: bool,

    #[arg(long, action, help = "Do not save history")]
    pub skip_history: bool,

    #[arg(long, action, help = "Do not resize or set wallpaper")]
    pub skip_wallpaper: bool,

    // TODO: pass through specific swww arguments?
    /*
    -f, --filter
    -t, --transition-type
    --transition-step
    --transition-duration
    --transition-fps
    --transition-angle
    --transition-pos
    --transition-bezier
    --transition-wave
    --invert-y
    */
    #[arg(long, action, help = "Transition type for swww")]
    pub transition: Option<String>,

    // optional image to use, uses a random one otherwise
    #[arg(
        action,
        value_hint = clap::ValueHint::AnyPath,
        value_name = "PATH",
        help = "An image or directory path, use - for stdin",
        // add = ArgValueCandidates::new(get_wallpaper_files)
    )]
    pub image_or_dir: Option<PathBuf>,
}
