use dotfiles::{full_path, rofi::Rofi, wallust};
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

fn preset_themes() -> Vec<ThemeEntry> {
    wallust_themes::COLS_KEY
        .into_iter()
        .zip(wallust_themes::COLS_VALUE)
        .map(|(name, colors)| {
            let swatches: Vec<String> = (0..8)
                .map(|color| format!("#{:06X}", colors[color]))
                .collect();

            ThemeEntry::new(name, &swatches)
        })
        .collect()
}

fn custom_themes() -> Vec<ThemeEntry> {
    wallust::CUSTOM_THEMES
        .into_iter()
        .map(|name| {
            let theme_file = full_path(format!("~/.config/wallust/themes/{name}.json"));

            // read theme as json
            let theme: serde_json::Value = serde_json::from_str(
                &std::fs::read_to_string(theme_file)
                    .unwrap_or_else(|_| panic!("failed to read custom theme: {name}")),
            )
            .unwrap_or_else(|_| panic!("failed to parse custom theme: {name}"));

            let swatches: Vec<String> = (0..8)
                .map(|i| {
                    if let Some(serde_json::Value::String(color)) = theme
                        .get("colors")
                        .and_then(|colors| colors.get(format!("color{i}")))
                    {
                        color.to_string()
                    } else {
                        panic!("failed to get color{i} for {name}");
                    }
                })
                .collect();

            ThemeEntry::new(name, &swatches)
        })
        .collect()
}

fn main() {
    let mut all_themes = preset_themes();
    all_themes.extend(custom_themes());

    all_themes.sort_by_key(|theme| theme.display_name.to_string());

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
