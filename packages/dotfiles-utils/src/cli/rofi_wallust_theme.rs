use dotfiles_utils::{cmd_output, wallpaper, wallust, CmdOutput};
use std::{
    io::Write,
    process::{Command, Stdio},
};

fn wallust_preset_themes() -> Vec<String> {
    cmd_output(["wallust", "theme", "--help"], CmdOutput::Stdout)
        .iter()
        .max_by_key(|line| line.len())
        .unwrap()
        .rsplit_once(" values: ")
        .unwrap()
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
            .iter()
            .map(|s| s.to_string())
            .collect::<Vec<_>>(),
    );
    preset_themes.sort();
    preset_themes
}

fn main() {
    let themes = all_themes().join("\n");

    let mut rofi = Command::new("rofi")
        .arg("-dmenu")
        .arg("-theme")
        .arg("~/.cache/wallust/rofi-menu.rasi")
        .stdout(Stdio::piped())
        .stdin(Stdio::piped())
        .spawn()
        .expect("failed to execute process");

    rofi.stdin
        .as_mut()
        .unwrap()
        .write_all(themes.as_bytes())
        .unwrap();

    let output = rofi.wait_with_output().expect("failed to read rofi theme");
    let selected_theme = std::str::from_utf8(&output.stdout)
        .expect("failed to parse utf8")
        .strip_suffix('\n')
        .unwrap_or_default();

    wallust::apply_theme(selected_theme.to_string());
    wallpaper::wallust_apply_colors();
}
