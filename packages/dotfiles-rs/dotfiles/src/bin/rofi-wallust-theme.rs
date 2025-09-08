use common::{full_path, rofi::Rofi, wallust};
use itertools::Itertools;

struct ThemeEntry {
    name: String,
    display_name: String,
    rofi: String,
}

impl ThemeEntry {
    /// swatches are in #RRGGBB format
    fn new(name: &str, swatches: &[String]) -> Self {
        let display_name = name
            .replace("base16-", "")
            .replace("dkeg-", "")
            .replace("sexy-", "")
            .replace("tempus_", "tempus-")
            .split('-')
            .map(|word| {
                let mut c = word.chars();
                match c.next() {
                    Some(first) => first.to_uppercase().collect::<String>() + c.as_str(),
                    None => String::new(),
                }
            })
            .collect_vec()
            .join(" ");

        let swatches = swatches
            .iter()
            .map(|swatch| format!("<span foreground=\"{swatch}\">\u{25A0}</span>"))
            .collect_vec()
            .join(" ");

        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            rofi: format!("{swatches}\t\t{display_name}"),
        }
    }
}

fn main() {
    let all_themes = wallust_themes::COLS_KEY
        .iter()
        .zip(wallust_themes::COLS_VALUE)
        .map(|(name, colors)| {
            let swatches: Vec<String> = (0..8)
                .map(|color| format!("#{:06X}", colors[color]))
                .collect();

            ThemeEntry::new(name, &swatches)
        })
        .sorted_by_key(|theme| theme.display_name.to_string())
        .collect_vec();

    // display with rofi
    let rofi = Rofi::new(
        &all_themes
            .iter()
            .map(|theme| theme.rofi.to_string())
            .collect_vec(),
    )
    .theme(full_path("~/.cache/wallust/rofi-menu.rasi"));

    let (sel, _) = rofi
        .arg("-i") // case insensitive
        .arg("-markup-rows") // needed for pango markup
        .run();

    let sel = &all_themes
        .iter()
        .find(|theme| theme.rofi == sel)
        .expect("failed to find selected theme")
        .name;

    if !sel.is_empty() {
        wallust::apply_theme(sel);
        wallust::apply_colors();
    }
}
