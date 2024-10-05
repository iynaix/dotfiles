use clap::{CommandFactory, Parser, ValueEnum};
use dotfiles::{full_path, generate_completions, CommandUtf8, ShellCompletion};
use itertools::Itertools;
use std::{
    fs::read_to_string,
    path::{Path, PathBuf},
};

#[derive(ValueEnum, Clone, Debug)]
pub enum RofiMpvMedia {
    Anime,
    TV,
}

#[derive(Parser, Debug)]
#[command(
    name = "rofi-media",
    about = "Plays the next episode of anime or tv shows"
)]
pub struct RofiMpvArgs {
    #[arg(value_enum)]
    pub media: Option<RofiMpvMedia>,

    #[arg(
        long,
        value_enum,
        help = "Type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

type Video = (PathBuf, String);

fn latest_file(media_type: &RofiMpvMedia) -> Video {
    let mut latest = PathBuf::new();
    let mut latest_content = String::new();

    for watch_file in full_path("~/.local/state/mpv/watch_later")
        .read_dir()
        .expect("could not read watch_later dir")
        .flatten()
    {
        let content = read_to_string(watch_file.path()).expect("could not read watch_later file");
        let vid = content
            .lines()
            .next()
            .expect("watch_later file is empty")
            .strip_prefix("# ")
            .expect("watch_later: no prefix for filename")
            .to_string();

        let vid_path = PathBuf::from(&vid);

        if !vid.contains("smb-share") && !vid_path.exists() {
            // println!("removing {vid_path:?}");
            // std::fs::remove_file(vid_path).expect("could not remove watch_later file");
            continue;
        }

        let is_current = match media_type {
            RofiMpvMedia::Anime => vid.contains("Anime/Current"),
            RofiMpvMedia::TV => vid.contains("TV/Current"),
        };

        if is_current && vid_path > latest {
            latest = vid_path;
            latest_content = content;
        }
    }
    (latest, latest_content)
}

/// gets the start time of a video in seconds
fn get_start_time(content: &str) -> f32 {
    let start_line = content
        .lines()
        .find(|line| line.starts_with("start="))
        .expect("no start time found");

    let (_, time) = start_line
        .rsplit_once('=')
        .unwrap_or_else(|| panic!("invalid start time: {start_line}"));
    time.parse()
        .unwrap_or_else(|_| panic!("invalid start time: {time}"))
}

/// gets the duration of a video in seconds
fn get_duration<P>(vid_path: P) -> f32
where
    P: AsRef<Path> + std::fmt::Debug,
{
    let ffmpeg = execute::command_args!(
        "ffmpeg",
        "-i",
        vid_path
            .as_ref()
            .to_str()
            .unwrap_or_else(|| panic!("could not convert video path {vid_path:?} to str")),
    )
    .execute_stderr_lines();
    let duration = ffmpeg
        .iter()
        .find(|line| line.contains("Duration: "))
        .expect("no duration found")
        .rsplit_once("Duration: ")
        .expect("could not extract duration")
        .1;

    let duration = duration
        .split_once(',')
        .unwrap_or_else(|| panic!("invalid duration: {duration}"))
        .0
        .split(':')
        .map(|t| {
            t.parse::<f32>()
                .unwrap_or_else(|_| panic!("invalid duration: {duration}"))
        })
        .collect_vec();

    match duration.len() {
        1 => duration[0],
        2 => duration[1].mul_add(60.0, duration[0]),
        3 => (duration[2] * 60.0).mul_add(60.0, duration[1].mul_add(60.0, duration[0])),
        _ => panic!("invalid duration: {duration:?}"),
    }
}

fn get_episode((path, content): Video) -> Option<PathBuf> {
    const WATCH_THRESHOLD: f32 = 0.95;

    // get start time in seconds
    let start = get_start_time(&content);
    let duration = get_duration(&path);

    if start / duration < WATCH_THRESHOLD {
        return Some(path);
    }

    // episode finished, look for next episode

    // get list of files in the current directory
    let current_files = path
        .read_dir()
        .unwrap_or_else(|_| panic!("could not read current directory: {path:?}"))
        .flatten()
        .map(|e| e.path())
        .sorted()
        .collect_vec();

    // get index of current file
    let current_index = current_files
        .iter()
        .position(|path| path == &path.clone())
        .unwrap_or_else(|| panic!("could not get index of {path:?}"));

    current_files
        .get(current_index + 1)
        .map(std::borrow::ToOwned::to_owned)
}

fn main() {
    let args = RofiMpvArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        return generate_completions("rofi-mpv", &mut RofiMpvArgs::command(), &shell);
    }

    let no_media = "No media type specified. Use 'anime' or 'tv'.";
    if args.media.is_none() {
        eprintln!("{no_media}");
        std::process::exit(1);
    }

    let video = latest_file(&args.media.unwrap_or_else(|| panic!("{no_media}")));

    if let Some(to_play) = get_episode(video) {
        println!("Playing {to_play:?}");
    }
}
