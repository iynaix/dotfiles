use execute::Execute;
use std::{path::PathBuf, process::Stdio};

use common::{
    full_path,
    wallpaper::{self, filter_images},
};

pub fn dedupe() {
    let walls_in = full_path("~/Pictures/wallpapers_in");

    // if the files exist both in walls in and wallpapers, i probably forgot to remove them
    let has_walls_in_dupes = filter_images(&walls_in).any(|path| {
        if let Some(fname) = PathBuf::from(&path).file_name() {
            return wallpaper::dir().join(fname).exists();
        }
        false
    });

    let mut cmd =
        execute::command_args!("czkawka_cli", "image", "--directories", &wallpaper::dir());

    if !has_walls_in_dupes {
        cmd.arg("--directories").arg(&walls_in);
    }

    cmd.stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .execute_output()
        .expect("failed to execute czkawka");
}
