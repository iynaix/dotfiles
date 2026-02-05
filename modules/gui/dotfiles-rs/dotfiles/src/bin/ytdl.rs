use std::{
    collections::BTreeSet,
    env,
    fs::File,
    io::{BufRead, BufReader, Write},
    path::PathBuf,
    process::Command,
};

use common::full_path;

fn downloaded_files(archive_path: &PathBuf) -> Vec<String> {
    if !archive_path.exists() {
        return Vec::new();
    }

    let file = File::open(archive_path).expect("unable to open ytdl archive");
    let reader = BufReader::new(file);

    reader
        .lines()
        .map_while(Result::ok)
        .filter_map(|line| line.strip_prefix("youtube ").map(str::to_string))
        .collect()
}

fn read_yt_txt() -> Vec<String> {
    let yt_txt = full_path("~/Desktop/yt.txt");

    let file = File::open(&yt_txt).expect("unable to open yt.txt");
    BufReader::new(file).lines().map_while(Result::ok).collect()
}

fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().skip(1).collect(); // skip program name
    // a url is provided, do not use yt.txt
    let use_yt_txt = !args.iter().any(|arg| arg.starts_with("http"));

    let lines = read_yt_txt();
    // use BTreeSet to dedupe while preserving order
    let mut urls: BTreeSet<_> = lines
        .iter()
        .filter(|line| line.starts_with("http"))
        .collect();

    // construct yt-dlp command
    let mut cmd = Command::new("yt-dlp");

    // write downloaded files to archive file
    let archive_path = full_path("/tmp/ytdl-archive.txt");
    cmd.arg("--download-archive").arg(&archive_path);

    // download with embedded subs
    cmd.args([
        "--write-auto-sub",
        "--embed-subs",
        "--sub-lang",
        "en,eng",
        "--convert-subs",
        "srt",
    ]);

    for arg in &args {
        cmd.arg(arg);
    }

    // filter out already downloaded files
    let already_downloaded = downloaded_files(&archive_path);
    urls.retain(|url| !already_downloaded.iter().any(|yt_id| url.contains(yt_id)));
    for url in &urls {
        cmd.arg(url);
    }

    // cd to Downloads and run yt-dlp
    let original_dir = env::current_dir()?;
    env::set_current_dir(full_path("~/Downloads"))?;
    let status = cmd.status()?;
    env::set_current_dir(&original_dir)?;

    // write yt.txt, removing already downloaded files
    if use_yt_txt {
        // re-read yt.txt in case it was modified while downloading
        let mut lines = read_yt_txt();

        // re-read the archive file to remove any files that were just downloaded
        let already_downloaded = downloaded_files(&archive_path);
        lines.retain(|line| !already_downloaded.iter().any(|yt_id| line.contains(yt_id)));

        // trim trailing lines
        while lines.last().is_some_and(|s| s.trim().is_empty()) {
            lines.pop();
        }

        let mut file = File::create(full_path("~/Desktop/yt.txt"))?;
        for line in lines {
            writeln!(file, "{line}")?;
        }
    }

    std::process::exit(status.code().unwrap_or(1))
}
