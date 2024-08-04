use dotfiles_utils::{rofi::Rofi, wallust, CommandUtf8};

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
    let themes = all_themes();

    let rofi = Rofi::new("rofi-menu-noinput.rasi", &themes);
    let mut cmd = rofi.prompt();
    let selected = rofi.run(&mut cmd);

    wallust::apply_theme(&selected);
    wallust::apply_colors();
}
