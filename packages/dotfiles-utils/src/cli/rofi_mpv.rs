use clap::Parser;
use dotfiles_utils::{
    cli::{RofiMpvArgs, RofiMpvMedia},
    cmd_output, full_path, CmdOutput,
};
use std::{
    fs::read_to_string,
    path::{Path, PathBuf},
};

type Video = (PathBuf, String);

fn latest_file(media_type: RofiMpvMedia) -> Video {
    let mut latest = PathBuf::new();
    let mut latest_content = String::new();

    for watch_file in full_path("~/.local/state/mpv/watch_later")
        .read_dir()
        .unwrap()
        .flatten()
    {
        let content = read_to_string(watch_file.path()).expect("could not read watch_later file");
        let vid = content
            .lines()
            .next()
            .expect("watch_later file is empty")
            .strip_prefix("# ")
            .expect("no prefix for filename")
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
fn get_start_time(content: String) -> f32 {
    let start_line = content
        .lines()
        .find(|line| line.starts_with("start="))
        .expect("no start time found");

    let (_, time) = start_line.rsplit_once('=').unwrap();
    time.parse().expect("invalid start time")
}

/// gets the duration of a video in seconds
fn get_duration<P: AsRef<Path>>(vid_path: P) -> f32 {
    let ffmpeg = cmd_output(
        ["ffmpeg", "-i", vid_path.as_ref().to_str().unwrap()],
        CmdOutput::Stderr,
    );
    let duration = ffmpeg
        .iter()
        .find(|line| line.contains("Duration: "))
        .expect("no duration found")
        .rsplit_once("Duration: ")
        .unwrap()
        .1;

    let duration: Vec<_> = duration
        .split_once(',')
        .unwrap()
        .0
        .split(':')
        .map(|t| t.parse::<f32>().unwrap())
        .collect();

    match duration.len() {
        1 => duration[0],
        2 => duration[0] + duration[1] * 60.0,
        3 => duration[0] + duration[1] * 60.0 + duration[2] * 60.0 * 60.0,
        _ => panic!("invalid duration"),
    }
}

fn get_episode((path, content): Video) -> Option<PathBuf> {
    // get start time in seconds
    let start = get_start_time(content);
    let duration = get_duration(&path);

    const WATCH_THRESHOLD: f32 = 0.95;

    if start / duration < WATCH_THRESHOLD {
        return Some(path);
    }

    // episode finished, look for next episode

    // get list of files in the current directory
    let mut current_files: Vec<_> = path
        .read_dir()
        .unwrap()
        .flatten()
        .map(|e| e.path())
        .collect();

    current_files.sort();

    // get index of current file
    let current_index = current_files
        .iter()
        .position(|path| path == &path.to_path_buf())
        .unwrap();

    current_files.get(current_index + 1).map(|p| p.to_owned())
}

fn main() {
    let args = RofiMpvArgs::parse();

    let video = latest_file(args.media);

    if let Some(to_play) = get_episode(video) {
        println!("Playing {to_play:?}");
    }
}
