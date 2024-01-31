use dotfiles_utils::{wallust, CommandUtf8};
use execute::Execute;
use std::process::Stdio;

fn wallust_preset_themes() -> Vec<String> {
    execute::command!("wallust theme --help")
        .execute_stdout_lines()
        .iter()
        .max_by_key(|line| line.len())
        .expect("could not parse wallust themes")
        .rsplit_once(" values: ")
        .expect("could not parse wallust themes")
        .1
        .replace(']', "")
        .split(", ")
        .map(String::from)
        .collect()
}

fn all_themes() -> Vec<String> {
    let mut preset_themes = wallust_preset_themes();

    preset_themes.extend_from_slice(
        &wallust::CUSTOM_THEMES
            .into_iter()
            .map(std::string::ToString::to_string)
            .collect::<Vec<_>>(),
    );
    preset_themes.sort();
    preset_themes
}

fn main() {
    let themes = all_themes().join("\n");

    let selected_theme = execute::command!("rofi -dmenu -theme ~/.cache/wallust/rofi-menu.rasi")
        .stdout(Stdio::piped())
        .execute_input_output(themes.as_bytes())
        .expect("failed to read rofi theme")
        .stdout;

    // let output = rofi.wait_with_output().expect("failed to read rofi theme");
    let selected_theme = std::str::from_utf8(&selected_theme)
        .expect("failed to parse utf8")
        .strip_suffix('\n')
        .unwrap_or_default();

    wallust::apply_theme(selected_theme);
    wallust::apply_colors();
}
