use clap::{builder::PossibleValuesParser, command, Parser, ValueEnum};
use dotfiles_utils::{cmd, cmd_output, wallpaper, CmdOutput};
use rand::seq::SliceRandom;
use std::{path::PathBuf, process::Command};

#[derive(Clone, ValueEnum, Debug)]
enum RofiType {
    Wallpaper,
    Theme,
}

fn swww(swww_args: &[&str]) {
    let is_daemon_running = !cmd_output(["swww", "query"], CmdOutput::Stderr)
        .first()
        .unwrap_or(&String::from(""))
        .starts_with("Error");

    if is_daemon_running {
        Command::new("swww")
            .args(swww_args)
            .spawn()
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
                .spawn()
                .expect("failed to execute process");
        }
    }
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr-wallpaper",
    about = "Changes the wallpaper and updates the colorcheme"
)]
struct Args {
    #[arg(long, value_name = "PATH", help = "path to a fallback wallpaper")]
    fallback: Option<PathBuf>,

    #[arg(long, action, help = "reload current wallpaper")]
    reload: bool,

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

    // optional image to use, uses a random one otherwise
    image: Option<PathBuf>,
}

fn main() {
    let args = Args::parse();

    let random_wallpaper = match args.image {
        Some(image) => Some(image.into_os_string().into_string().unwrap()),
        None => {
            let wallpapers = wallpaper::all();

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

    if args.reload {
        let wallpaper = wallpaper::current()
            .or(random_wallpaper)
            .expect("no wallpaper found");

        if !args.no_wallust {
            cmd(["wallust", &wallpaper])
        }

        swww(&["img", &wallpaper]);
        cmd(["killall", "-SIGUSR2", ".waybar-wrapped"])
    } else {
        let wallpaper = &random_wallpaper.expect("no wallpaper found");

        if !args.no_wallust {
            cmd(["wallust", wallpaper]);
        }

        swww(&["img", "--transition-type", &args.transition_type, wallpaper]);
    }

    wallpaper::wallust_apply_colors();
}
