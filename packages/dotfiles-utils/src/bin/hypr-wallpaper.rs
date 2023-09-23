use clap::{builder::PossibleValuesParser, command, Parser, ValueEnum};
use dirs::{cache_dir, home_dir};
use dotfiles_utils::{cmd, hypr, hypr_monitors, load_json_file, WallustColors};
use rand::{seq::SliceRandom, Rng};
use std::{
    error::Error,
    io::Write,
    path::PathBuf,
    process::{exit, Command, Stdio},
};

#[derive(Clone, ValueEnum, Debug)]
enum RofiType {
    Wallpaper,
    Theme,
}

const CUSTOM_THEMES: [&str; 6] = [
    "catppuccin-frappe",
    "catppuccin-macchiato",
    "catppuccin-mocha",
    "decay-dark",
    "night-owl",
    "tokyo-night",
];

fn wallpaper_dir() -> PathBuf {
    let mut d = home_dir().unwrap_or_default();
    d.push("Pictures/Wallpapers");
    d
}

fn wallust_preset_themes() -> Vec<String> {
    let output = Command::new("wallust")
        .args(["theme", "--help"])
        .output()
        .expect("failed to execute process");

    let (_, themes) = std::str::from_utf8(&output.stdout)
        .unwrap()
        .lines()
        .max_by_key(|line| line.len())
        .unwrap()
        .rsplit_once(" values: ")
        .unwrap();

    themes
        .replace(']', "")
        .split(", ")
        .map(String::from)
        .collect()
}

fn all_themes() -> Vec<String> {
    let mut preset_themes = wallust_preset_themes();

    preset_themes.extend_from_slice(
        &CUSTOM_THEMES
            .iter()
            .map(|s| s.to_string())
            .collect::<Vec<_>>(),
    );
    preset_themes.sort();
    preset_themes
}

fn get_wallust_colors() -> Result<WallustColors, Box<dyn Error>> {
    let mut colors_file = cache_dir().unwrap_or_default();
    colors_file.push("wallust/colors.json");

    load_json_file(&colors_file)
}

fn get_current_wallpaper() -> Option<String> {
    let curr = get_wallust_colors()
        .expect("could not get colors")
        .wallpaper;

    let wallpaper = {
        if curr != "./foo/bar.text" {
            Some(curr)
        } else {
            let output = Command::new("swww")
                .arg("query")
                .output()
                .expect("failed to execute process");

            let (_, img) = std::str::from_utf8(&output.stdout)
                .unwrap()
                .lines()
                .next()
                .expect("no wallpaper found")
                .rsplit_once(": ")
                .expect("no wallpaper found");

            Some(img.to_string())
        }
    };

    Some(
        wallpaper
            .expect("no wallpaper found")
            .replace("/persist", ""),
    )
}

fn rofi_theme() {
    let themes = all_themes().join("\n");

    let mut rofi = Command::new("rofi")
        .arg("-dmenu")
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

    apply_wallust_theme(selected_theme.to_string());
    apply_colors();
}

fn get_wallpapers() -> Vec<String> {
    let curr = get_current_wallpaper().unwrap_or_default();

    wallpaper_dir()
        .read_dir()
        .unwrap()
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();

            if path.is_file() {
                if let Some(ext) = path.extension() {
                    match ext.to_str() {
                        Some("jpg") | Some("jpeg") | Some("png") => {
                            if curr == *path.to_str().unwrap() {
                                return None;
                            }

                            return Some(path.to_str().unwrap().to_string());
                        }
                        _ => {}
                    }
                }
            }

            None
        })
        .collect()
}

fn rofi_wallpaper() {
    // let new_wallpaper = random_wallpaper();
    const TARGET_PERCENT: f32 = 0.3;

    let mon = hypr_monitors().into_iter().find(|mon| mon.focused).unwrap();

    let mut width = mon.width * TARGET_PERCENT;
    let mut height = mon.height * TARGET_PERCENT;

    // handle vertical monitor
    if height > width {
        std::mem::swap(&mut width, &mut height);
    }

    let float_rule = format!("[float;size {} {};center]", width as i32, height as i32);

    // to behave like rofi
    let esc_bind = "bind <Escape> quit";
    let rand_idx = rand::thread_rng().gen_range(1..=get_wallpapers().len());

    hypr(&[
        "exec",
        format!(
            "{} imv -n {} -c '{}' {}",
            float_rule,
            rand_idx,
            esc_bind,
            wallpaper_dir().as_os_str().to_str().unwrap()
        )
        .as_str(),
    ]);
}

fn apply_wallust_theme(theme: String) {
    if CUSTOM_THEMES.contains(&theme.as_str()) {
        let mut colorscheme_file = cache_dir().unwrap_or_default();
        colorscheme_file.push(format!("wallust/{}.json", theme));

        cmd(&["wallust", "cs", colorscheme_file.to_str().unwrap()])
    } else {
        cmd(&["wallust", "theme", &theme])
    }
}

fn refresh_zathura() {
    let output = Command::new("dbus-send")
        .args([
            "--print-reply",
            "--dest=org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus.ListNames",
        ])
        .output()
        .expect("failed to execute process");

    if let Some(zathura_pid_raw) = std::str::from_utf8(&output.stdout)
        .unwrap()
        .lines()
        .find(|line| line.contains("org.pwmt.zathura"))
    {
        let zathura_pid = zathura_pid_raw.split('"').max_by_key(|s| s.len()).unwrap();

        // send message to zathura via dbus
        cmd(&[
            "dbus-send",
            "--type=method_call",
            format!("--dest={}", zathura_pid).as_str(),
            "/org/pwmt/zathura",
            "org.pwmt.zathura.ExecuteCommand",
            "string:source",
        ]);
    }
}

fn apply_colors() {
    let colors = get_wallust_colors().expect("could not get colors");

    // remove the hex prefix for colors
    let c: Vec<_> = (0..16)
        .map(|n| {
            let k = format!("color{}", n);
            colors.colors.get(&k).unwrap().replace('#', "")
        })
        .collect();

    // update borders
    cmd(&[
        "hyprctl",
        "keyword",
        "general:col.active_border",
        &format!("{} {} 45deg", c[4], c[0]),
    ]);
    cmd(&["hyprctl", "keyword", "general:col.inactive_border", &c[0]]);

    // pink border for monocle windows
    cmd(&[
        "hyprctl",
        "keyword",
        "windowrulev2",
        "bordercolor",
        &format!("{},fullscreen:1", &c[5]),
    ]);
    // teal border for floating windows
    cmd(&[
        "hyprctl",
        "keyword",
        "windowrulev2",
        "bordercolor",
        &format!("{},floating:1", &c[6]),
    ]);
    // yellow border for sticky (must be floating) windows
    cmd(&[
        "hyprctl",
        "keyword",
        "windowrulev2",
        "bordercolor",
        &format!("{},pinned:1", &c[3]),
    ]);

    // refresh zathura
    refresh_zathura();

    // refresh cava
    cmd(&["killall", "-SIGUSR2", "cava"]);

    // refresh waifufetch
    cmd(&["killall", "-SIGUSR2", "python3"]);

    // refresh waybar
    cmd(&["killall", "-SIGUSR2", ".waybar-wrapped"]);

    // reload gtk theme
    // reload_gtk()
}

fn swww(swww_args: &[&str]) {
    let swww_query = Command::new("swww")
        .arg("query")
        .output()
        .expect("failed to execute process");

    // check if swww daemon is running
    let is_daemon_running = !std::str::from_utf8(&swww_query.stderr)
        .unwrap()
        .lines()
        .next()
        .unwrap_or_default()
        .starts_with("Error");

    if is_daemon_running {
        Command::new("swww")
            .args(swww_args)
            .status()
            .expect("failed to execute process");
    } else {
        // FIXME: weird race condition with swww init, need to sleep for a second
        // https://github.com/Horus645/swww/issues/144

        // sleep for a second
        std::thread::sleep(std::time::Duration::from_secs(1));

        let swww_init = Command::new("swww")
            .arg("init")
            .status()
            .expect("failed to execute swww init");

        // equivalent of bash &&
        if swww_init.success() {
            Command::new("swww")
                .args(swww_args)
                .status()
                .expect("failed to execute process");
        }
    }
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr_wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
struct Args {
    #[arg(long, value_name = "PATH", help = "path to a fallback wallpaper")]
    fallback: Option<PathBuf>,

    #[arg(long, action, help = "reload current wallpaper")]
    reload: bool,

    #[arg(long, value_enum, help = "use rofi to select wallpaper or theme")]
    rofi: Option<RofiType>,

    #[arg(
        long,
        action,
        help = "do not use wallust to generate colorschemes for programs"
    )]
    no_wallust: bool,

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
    transition_type: String,

    #[arg(
        long,
        help = "preset theme for wallust",
        value_parser = PossibleValuesParser::new(all_themes()),
    )]
    theme: Option<String>,

    // optional image to use, uses a random one otherwise
    image: Option<PathBuf>,
}

fn main() {
    let args = Args::parse();

    match args.rofi {
        Some(RofiType::Theme) => {
            rofi_theme();
            exit(0)
        }
        Some(RofiType::Wallpaper) => {
            rofi_wallpaper();
            exit(0)
        }
        None => {}
    }

    let wallpaper = match args.image {
        Some(image) => Some(image.into_os_string().into_string().unwrap()),
        None => {
            let wallpapers = get_wallpapers();

            if wallpapers.is_empty() {
                args.fallback
                    .map(|fallback| fallback.into_os_string().into_string().unwrap())
            } else {
                Some(
                    wallpapers
                        .choose(&mut rand::thread_rng())
                        .unwrap()
                        .to_string(),
                )
            }
        }
    };

    if let Some(theme) = args.theme {
        apply_wallust_theme(theme);
        exit(0)
    } else if args.reload {
        let wallpaper = get_current_wallpaper()
            .or(wallpaper)
            .expect("no wallpaper found");

        if !args.no_wallust {
            cmd(&["wallust", &wallpaper])
        }

        swww(&["img", &wallpaper]);
        cmd(&["launch_waybar"])
    } else {
        let wallpaper = &wallpaper.expect("no wallpaper found");

        if !args.no_wallust {
            cmd(&["wallust", wallpaper]);
        }

        swww(&[
            "img",
            "--transition-type",
            args.transition_type.as_str(),
            wallpaper,
        ]);
    }

    apply_colors();
}
