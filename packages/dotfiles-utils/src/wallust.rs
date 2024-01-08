use crate::{cmd, full_path};

pub const CUSTOM_THEMES: [&str; 6] = [
    "catppuccin-frappe",
    "catppuccin-macchiato",
    "catppuccin-mocha",
    "decay-dark",
    "night-owl",
    "tokyo-night",
];

pub fn apply_theme(theme: String) {
    if CUSTOM_THEMES.contains(&theme.as_str()) {
        let colorscheme_file = full_path(format!("~/.config/wallust/{theme}.json"));
        cmd(["wallust", "cs", colorscheme_file.to_str().unwrap()])
    } else {
        cmd(["wallust", "theme", &theme])
    }
}
