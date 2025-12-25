use std::{collections::HashMap, path::PathBuf};

use common::{full_path, wallpaper};

pub fn write_wallpaper_history(wallpaper: PathBuf) {
    // not a wallpaper from the wallpapers dir
    if wallpaper.parent() != Some(&wallpaper::dir()) {
        return;
    }

    let mut history: HashMap<_, _> = wallpaper::history().into_iter().collect();
    // insert or update timestamp
    history.insert(wallpaper, chrono::Local::now().into());

    // update the history csv
    let history_csv = full_path("~/Pictures/wallpapers_history.csv");
    let writer = std::io::BufWriter::new(
        std::fs::File::create(history_csv).expect("could not create wallpapers_history.csv"),
    );
    let mut wtr = csv::WriterBuilder::new()
        .has_headers(false)
        .from_writer(writer);

    for (path, dt) in &history {
        let filename = path
            .file_name()
            .expect("could not get timestamp filename")
            .to_str()
            .expect("could not convert filename to str");

        let row = [
            filename,
            &dt.to_rfc3339_opts(chrono::SecondsFormat::Secs, true),
        ];

        wtr.write_record(row)
            .unwrap_or_else(|_| panic!("could not write {row:?}"));
    }
    wtr.flush().expect("could not flush wallpapers_history.csv");
}
