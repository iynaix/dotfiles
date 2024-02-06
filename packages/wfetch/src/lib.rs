use crate::{cli::WFetchArgs, wallpaper::WallInfo};
use chrono::{DateTime, Datelike, NaiveDate, Timelike};
use execute::Execute;
use serde_json::{json, Value};
use std::{
    collections::HashMap,
    env,
    path::PathBuf,
    process::{Command, Stdio},
};

pub mod cli;
pub mod wallpaper;

pub fn full_path<P>(p: P) -> PathBuf
where
    P: AsRef<std::path::Path>,
{
    let p = p.as_ref().to_str().expect("invalid path");

    match p.strip_prefix("~/") {
        Some(p) => dirs::home_dir().expect("invalid home directory").join(p),
        None => PathBuf::from(p),
    }
}

pub trait CommandUtf8 {
    fn execute_stdout_lines(&mut self) -> Vec<String>;
}

impl CommandUtf8 for std::process::Command {
    fn execute_stdout_lines(&mut self) -> Vec<String> {
        self.stdout(Stdio::piped()).execute_output().map_or_else(
            |_| Vec::new(),
            |output| {
                String::from_utf8(output.stdout)
                    .expect("invalid utf8 from command")
                    .lines()
                    .map(String::from)
                    .collect()
            },
        )
    }
}

#[cfg(feature = "wfetch-waifu")]
pub const fn arg_waifu(args: &WFetchArgs) -> bool {
    args.waifu
}

#[cfg(not(feature = "wfetch-waifu"))]
pub const fn arg_waifu(_args: &WFetchArgs) -> bool {
    false
}

pub fn asset_path(filename: &str) -> String {
    let out_path = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| {
        env::current_exe()
            .expect("could not get current dir")
            .ancestors()
            .nth(2)
            .expect("could not get base package dir")
            .to_str()
            .expect("could not convert base package dir to str")
            .to_string()
    }));
    let asset = out_path.join("assets").join(filename);
    asset
        .to_str()
        .unwrap_or_else(|| panic!("could not get asset {}", &filename))
        .to_string()
}

fn create_output_file(filename: String) -> String {
    let output_dir = full_path("~/.cache/wfetch");
    std::fs::create_dir_all(&output_dir).expect("failed to create output dir");

    output_dir
        .join(filename)
        .to_str()
        .expect("could not convert output dir to str")
        .to_string()
}

fn create_nixos_logo(args: &WFetchArgs) -> String {
    let contents = std::fs::read_to_string(full_path("~/.cache/wallust/nix.json"))
        .unwrap_or_else(|_| panic!("failed to load nix.jspn"));

    let hexless = serde_json::from_str::<HashMap<String, HashMap<String, String>>>(&contents)
        .unwrap_or_else(|_| panic!("failed to parse nix.json"));
    let hexless = hexless
        .get("colors")
        .unwrap_or_else(|| panic!("failed to get colors"));

    // let hexless = NixInfo::after().colors;
    let c1 = hexless.get("color4").expect("invalid color");
    let c2 = hexless.get("color6").expect("invalid color");

    let output = create_output_file(format!("{c1}-{c2}.png"));
    let image_size = args
        .image_size
        .unwrap_or(if args.challenge { 420 } else { 340 });

    execute::command_args!(
        "convert",
        // replace color 1
        &asset_path("nixos.png"),
        "-fuzz",
        "10%",
        "-fill",
        c1,
        "-opaque",
        "#5278c3",
        // replace color 2
        "-fuzz",
        "10%",
        "-fill",
        c2,
        "-opaque",
        "#7fbae4",
        "-resize",
        format!("{image_size}x{image_size}"),
        output,
    )
    .execute()
    .expect("failed to create nixos logo");

    output
}

fn imagemagick_wallpaper(args: &WFetchArgs, wallpaper_arg: &Option<String>) -> Command {
    // read current wallpaper
    let wall = wallpaper::detect(wallpaper_arg).unwrap_or_else(|| {
        eprintln!("Error: could not detect wallpaper!");
        std::process::exit(1);
    });

    let wallpaper_info = wallpaper::info(&wall);

    let crop_area = if let Some(WallInfo {
        r1x1: crop_area, ..
    }) = &wallpaper_info
    {
        crop_area.to_owned()
    } else {
        let (width, height) =
            image::image_dimensions(&wall).expect("could not get image dimensions");

        // get square crop for imagemagick
        if width > height {
            format!("{height}x{height}+{}+0", (width - height) / 2)
        } else {
            format!("{width}x{width}+0+{}", (height - width) / 2)
        }
    };

    let image_size = args
        .image_size
        .unwrap_or(if args.challenge { 380 } else { 300 });

    // use imagemagick to crop and resize the wallpaper
    execute::command_args!(
        "convert",
        wall,
        "-crop",
        crop_area,
        "-resize",
        format!("{image_size}x{image_size}"),
    )
}

/// creates the wallpaper image that fastfetch will display
fn create_wallpaper_image(args: &WFetchArgs) -> String {
    let output = create_output_file("wallpaper.png".to_string());

    imagemagick_wallpaper(args, &args.wallpaper)
        .arg(&output)
        .execute()
        .expect("failed to execute imagemagick");

    output
}

/// creates the wallpaper ascii that fastfetch will display
pub fn show_wallpaper_ascii(args: &WFetchArgs, fastfetch: &mut Command) {
    let mut imagemagick = imagemagick_wallpaper(args, &args.wallpaper_ascii);
    imagemagick.arg("-");

    let mut ascii_converter = Command::new("ascii-image-converter");
    ascii_converter
        .arg("--color")
        .arg("--braille")
        .arg("--width")
        .arg(args.ascii_size.to_string())
        .arg("-"); // load from stdin

    imagemagick
        .execute_multiple_output(&mut [&mut ascii_converter, fastfetch])
        .expect("failed to show ascii wallpaper");
}

pub fn shell_module() -> serde_json::Value {
    // HACK: fastfetch detects the process as wfetch, detect it via STARSHIP_SHELL
    if std::env::var("STARSHIP_SHELL").unwrap_or_default() == "fish" {
        let fish_version = execute::command!("fish --version")
            .execute_stdout_lines()
            .first()
            .expect("could not run fish")
            .split(' ')
            .last()
            .expect("could not parse fish version")
            .to_string();

        json!({
            "type": "command",
            "key": "󰈺 SH",
            "text": format!("echo \"fish {}\"", fish_version),
        })
    } else {
        json!({ "type": "shell", "key": " SH", "format": "{3}" })
    }
}

fn os_module() -> serde_json::Value {
    let os = if execute::command!("uname -a")
        .execute_stdout_lines()
        .join(" ")
        .contains("NixOS")
    {
        ""
    } else {
        ""
    };

    json!({ "type": "os", "key": format!("{os} OS"), "format": "{3}" })
}

fn wm_module() -> serde_json::Value {
    let mut is_de = false;
    let key = match env::var("XDG_CURRENT_DESKTOP")
        .unwrap_or_default()
        .to_lowercase()
        .as_str()
    {
        "hyprland" => "",
        "gnome" => {
            is_de = true;
            ""
        }
        "kde" => {
            is_de = true;
            ""
        }
        _ => "󰕮",
    };

    if is_de {
        json!({ "type": "de", "key": format!("{key} DE"), "format": "{2} ({3})" })
    } else {
        json!({ "type": "wm", "key": format!("{key} WM"), "format": "{2}" })
    }
}

#[allow(clippy::similar_names)] // gpu and cpu trips this
pub fn create_fastfetch_config(args: &WFetchArgs, config_jsonc: &str) {
    let os = os_module();
    let kernel = json!({ "type": "kernel", "key": " VER", });
    let uptime = json!({ "type": "uptime", "key": "󰅐 UP", });
    let packages = json!({ "type": "packages", "key": "󰏖 PKG", });
    let display = json!({ "type": "display", "key": "󰍹 RES", "compactType": "scaled" });
    let wm = wm_module();
    let terminal = json!({ "type": "terminal", "key": " TER", "format": "{3}" });
    let cpu = json!({ "type": "cpu", "key": " CPU", "format": "{1} ({5})", });
    let gpu = json!({ "type": "gpu", "key": " GPU", "driverSpecific": true, "format": "{2}", "forceVulkan": true, "hideType": "integrated" });
    let memory =
        json!({ "type": "memory", "key": "󰆼 RAM", "format": "{/1}{-}{/}{/2}{-}{/}{} / {}" });
    let color = json!({ "type": "colors", "symbol": "circle", });

    // handle logo
    let mut logo = json!({ "source": "nixos" });

    if args.hollow {
        let hollow = asset_path("nixos_hollow.txt");
        logo = json!({
            "source": hollow,
            "color": {
                "1": "blue",
                "2": "cyan",
            }
        });
    } else if args.wallpaper.is_some() {
        logo = json!({
            // ghostty supports kitty image protocol
            "type": "kitty-direct",
            "source": create_wallpaper_image(args),
            "preserveAspectRatio": true,
        });
    } else if args.wallpaper_ascii.is_some() {
        logo = json!({
            "type": "auto",
            "source": "-"
        });
    } else if arg_waifu(args) {
        logo = json!({
            // ghostty supports kitty image protocol
            "type": "kitty-direct",
            "source": create_nixos_logo(args),
            "preserveAspectRatio": true,
        });
    }

    let mut modules = vec![
        os,
        kernel,
        uptime,
        packages,
        json!("break"),
        cpu,
        gpu,
        memory,
        json!("break"),
        display,
        wm,
        terminal,
        shell_module(),
    ];

    // set colors for modules
    if !args.no_color_keys {
        let colors = ["green", "yellow", "blue", "magenta", "cyan"];
        for (i, module) in modules.iter_mut().enumerate() {
            if let Value::Object(module) = module {
                module.insert("keyColor".into(), json!(colors[i % colors.len()]));
            }
        }
    }

    // optional challenge block
    if args.challenge {
        modules.extend_from_slice(&challenge_block(args));
    }

    modules.extend_from_slice(&[json!("break"), color]);

    let contents = json!( {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "display": {
            "separator": "   ",
            // icon + space + 3 letters + separator
            "keyWidth": 1 + 1 + 3 + 3,
            "binaryPrefix": "si",
        },
        "logo": logo,
        "modules": modules,
    });

    // write json to file
    let file = std::fs::File::create(full_path(config_jsonc))
        .unwrap_or_else(|_| panic!("failed to create json config"));
    serde_json::to_writer(file, &contents)
        .unwrap_or_else(|_| panic!("failed to write json config"));
}

fn term_color(color: i32, text: &String, bold: bool) -> String {
    let bold_format = if bold { "1;" } else { "" };
    format!("\u{1b}[{bold_format}{}m{text}\u{1b}[0m", 30 + color)
}

fn last_day_of_month(year: i32, month: u32) -> u32 {
    let month = if month == 12 { 1 } else { month };
    let year = if month == 12 { year + 1 } else { year };

    let first_day_of_next_month = NaiveDate::from_ymd_opt(year, month + 1, 1).expect("");
    (first_day_of_next_month - chrono::Duration::days(1)).day()
}

#[allow(clippy::cast_precision_loss, clippy::cast_possible_wrap)]
pub fn challenge_text(args: &WFetchArgs) -> String {
    let start = DateTime::parse_from_str(&args.challenge_timestamp.to_string(), "%s")
        .expect("could not parse start timestamp");

    let mths = args.challenge_months % 12;
    let yrs = args.challenge_years + args.challenge_months / 12;

    let final_mth = if start.month() + mths > 12 {
        start.month() + mths - 12
    } else {
        start.month() + mths
    };
    let final_yr = if start.month() + mths > 12 {
        start.year() + yrs as i32 + 1
    } else {
        start.year() + yrs as i32
    };
    let final_day = std::cmp::min(start.day(), last_day_of_month(final_yr, final_mth));

    let end = NaiveDate::from_ymd_opt(final_yr, final_mth, final_day)
        .expect("invalid end date")
        .and_time(
            chrono::NaiveTime::from_hms_opt(start.hour(), start.minute(), start.second())
                .expect("invalid end time"),
        );

    let now = chrono::offset::Local::now();

    let elapsed = now.timestamp() - start.timestamp();
    let total = end.timestamp() - start.timestamp();

    let percent = elapsed as f32 / total as f32 * 100.0;

    let elapsed_days = elapsed / 60 / 60 / 24;
    let total_days = total / 60 / 60 / 24;

    format!("{elapsed_days} Days / {total_days} Days ({percent:.2}%)")
}

pub fn challenge_title(args: &WFetchArgs) -> String {
    let mut segments: Vec<String> = Vec::new();
    segments.push(if args.challenge_years == 0 {
        String::new()
    } else {
        format!("{} YEAR", args.challenge_years)
    });

    segments.push(if args.challenge_months == 0 {
        String::new()
    } else {
        format!("{} MONTH", args.challenge_months)
    });

    segments.push(match &args.challenge_type {
        None => String::new(),
        Some(t) => t.to_owned().to_uppercase(),
    });

    let title = segments
        .into_iter()
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join(" ");

    format!("  {title} CHALLENGE  ")
}

pub fn challenge_block(args: &WFetchArgs) -> Vec<serde_json::Value> {
    let title = challenge_title(args);
    let body = challenge_text(args);
    let maxlen = std::cmp::max(title.len(), body.len());

    let title = json!({
        "type": "custom",
        "format": term_color(3, &format!("{title:^maxlen$}"), true),
    });
    let sep = json!({
        "type": "custom",
        // fill line with box drawing dash
        "format": term_color(3, &format!("{:─^maxlen$}", ""), false),
    });
    let body = json!({
        "type": "custom",
        "format": body,
    });

    vec![json!("break"), title, sep, body]
}
