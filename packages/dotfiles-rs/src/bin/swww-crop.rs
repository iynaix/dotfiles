use clap::{CommandFactory, Parser};
use dotfiles::{
    filename, full_path, generate_completions,
    monitor::Monitor,
    wallpaper::{self, WallInfo},
    ShellCompletion,
};
use execute::Execute;
use rand::seq::SliceRandom;
use rayon::prelude::*;
use std::{path::PathBuf, process::Stdio};

#[derive(Parser, Debug)]
#[command(
    name = "swww-crop",
    about = "Applies image crops for wallpapers on each monitor"
)]
pub struct SwwwCropArgs {
    // optional image to use, uses a random one otherwise
    pub image: Option<PathBuf>,

    #[arg(long, value_enum, help = "type of shell completion to generate")]
    pub generate_completions: Option<ShellCompletion>,
}

// choose a random transition, taken from ZaneyOS
// https://gitlab.com/Zaney/zaneyos/-/blob/main/config/scripts/wallsetter.nix
fn get_random_transition() -> Vec<String> {
    let transitions = [
        vec![
            "--transition-type",
            "wave",
            "--transition-angle",
            "120",
            "--transition-step",
            "30",
        ],
        vec![
            "--transition-type",
            "wipe",
            "--transition-angle",
            "30",
            "--transition-step",
            "30",
        ],
        vec!["--transition-type", "center", "--transition-step", "30"],
        vec![
            "--transition-type",
            "outer",
            "--transition-pos",
            "0.3,0.8",
            "--transition-step",
            "30",
        ],
        vec![
            "--transition-type",
            "wipe",
            "--transition-angle",
            "270",
            "--transition-step",
            "30",
        ],
    ];

    transitions
        .choose(&mut rand::thread_rng())
        .expect("could not choose transition")
        .iter()
        .map(std::string::ToString::to_string)
        .collect()
}

fn get_wallpaper_info(image: &String) -> Option<WallInfo> {
    let wallpapers_csv = full_path("~/Pictures/Wallpapers/wallpapers.csv");
    if !wallpapers_csv.exists() {
        return None;
    }

    // convert image to path
    let image = PathBuf::from(image);
    let fname = filename(image);

    let reader = std::io::BufReader::new(
        std::fs::File::open(wallpapers_csv).expect("could not open wallpapers.csv"),
    );

    let mut rdr = csv::Reader::from_reader(reader);
    rdr.deserialize::<WallInfo>()
        .flatten()
        .find(|line| line.filename == fname)
}

fn swww_default(image: &String, transition_args: &Vec<String>) {
    execute::command_args!("swww", "img")
        .args(transition_args)
        .arg(image)
        .execute()
        .expect("failed to set wallpaper");
}

fn swww_with_crop(
    image: &String,
    mon: &Monitor,
    wall_info: &WallInfo,
    transition_args: &Vec<String>,
) {
    let dimensions = mon.dimension_str();

    let Some(geometry) = wall_info.get_geometry(mon.width, mon.height) else {
        panic!("unable to get geometry for {}: {}", mon.name, dimensions);
    };

    let mut imagemagick = execute::command("magick");
    imagemagick
        .arg(image)
        .arg("-strip")
        .arg("-crop")
        .arg(geometry)
        .arg("-resize")
        .arg(dimensions)
        // output to stdin for piping
        .arg("-");

    let mut swww = execute::command_args!("swww", "img", "--no-resize");
    swww.arg("--outputs")
        .arg(&mon.name)
        .args(transition_args)
        // use stdin
        .arg("-")
        .stdout(Stdio::piped());

    imagemagick
        .execute_multiple(&mut [&mut swww])
        .expect("failed to execute swww");
}

fn main() {
    let args = SwwwCropArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate_completions {
        return generate_completions("hypr-monitors", &mut SwwwCropArgs::command(), &shell);
    }

    let wall = match args.image {
        Some(image) => std::fs::canonicalize(image)
            .expect("invalid image path")
            .to_str()
            .expect("could not convert image path to str")
            .to_string(),
        None => wallpaper::random(),
    };

    let transition_args = get_random_transition();

    // get the WallInfo for the image if it exists
    let Some(wall_info) = get_wallpaper_info(&wall) else {
        swww_default(&wall, &transition_args);
        return;
    };

    // set the wallpaper per monitor
    let monitors = Monitor::monitors();

    // bail if any monitor doesn't have geometry info
    if monitors
        .iter()
        .any(|m| wall_info.get_geometry(m.width, m.height).is_none())
    {
        swww_default(&wall, &transition_args);
        return;
    }

    Monitor::monitors()
        .par_iter()
        .for_each(|mon| swww_with_crop(&wall, mon, &wall_info, &transition_args));
}
