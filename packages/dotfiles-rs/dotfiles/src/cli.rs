use clap::{Parser, Subcommand, ValueEnum, value_parser};

// utilities for generating shell completions
#[derive(Subcommand, ValueEnum, Debug, Clone, PartialEq, Eq)]
pub enum ShellCompletion {
    Bash,
    Zsh,
    Fish,
}

#[derive(ValueEnum, Debug, Clone)]
pub enum MonitorExtend {
    Primary,
    Secondary,
}

#[derive(Parser, Debug, Default)]
#[command(name = "wm-monitors", about = "Re-arranges workspaces to monitor")]
/// Utilities for working with adding or removing monitors in hyprland
/// Without arguments, it redistributes the workspaces across all monitors
pub struct WmMonitorArgs {
    #[arg(
        long,
        value_parser = value_parser!(MonitorExtend),
        help = "Set new monitor(s) to be primary or secondary"
    )]
    pub extend: Option<MonitorExtend>,

    #[arg(long, name = "MONITOR", action, help = "Mirrors the primary monitor")]
    pub mirror: Option<String>,

    // show rofi menu for selecting monitor
    #[arg(long, action, help = "Show rofi menu for monitor options")]
    pub rofi: Option<String>,

    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

#[derive(ValueEnum, Clone, Debug)]
pub enum Direction {
    Next,
    Prev,
}

#[derive(Parser, Debug)]
#[command(
    name = "wm-same-class",
    about = "Focus next / prev window of same class"
)]
pub struct WmSameClassArgs {
    #[arg(value_enum)]
    pub direction: Option<Direction>,

    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

#[derive(Parser, Debug)]
#[command(
    name = "niri-resize-workspace",
    about = "Resize windows within workspace"
)]
pub struct NiriResizeWorkspaceArgs {
    #[arg(
        action,
        help = "Optional workspace number to resize, defaults to focused workspace"
    )]
    pub workspace: Option<u64>,

    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

#[derive(ValueEnum, Clone, Debug)]
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
    #[arg(value_enum)]
    pub media: Option<RofiMpvMedia>,

    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}
