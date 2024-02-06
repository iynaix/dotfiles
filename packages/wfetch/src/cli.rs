use clap::Parser;

#[allow(clippy::struct_excessive_bools)]
#[derive(Parser, Debug)]
#[command(name = "wfetch", about = "iynaix's custom fetch")]
pub struct WFetchArgs {
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

    #[arg(long, action, help = "type of the challenge, e.g. emacs")]
    pub challenge_type: Option<String>,

    #[arg(long, action, help = "listen for SIGUSR2")]
    pub listen: bool,

    #[arg(long, action, help = "do not show colored keys")]
    pub no_color_keys: bool,

    #[arg(long, action, help = "image size in pixels")]
    pub image_size: Option<i32>,

    #[arg(long, action, default_value = "70", help = "ascii size in characters")]
    pub ascii_size: i32,
}
