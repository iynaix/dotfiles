use serde::Deserialize;
use std::{
    fs,
    path::{Path, PathBuf},
};

#[derive(Debug, Deserialize)]
pub struct ImpermanencePaths {
    pub directories: Vec<String>,
    pub files: Vec<String>,
}

fn walk_persist(dir: &Path, persist_paths: &[String]) -> std::io::Result<()> {
    for entry in fs::read_dir(dir)? {
        let path = entry?.path();
        let path_str = path.display().to_string();

        if path.is_symlink() {
            continue;
        }

        if (path.is_dir() || path.is_file())
            && persist_paths.iter().any(|p| path_str.starts_with(p))
        {
            continue;
        }

        let is_parent_dir = persist_paths.iter().any(|p| p.starts_with(&path_str));
        if !is_parent_dir {
            println!("{}", path.display());
        }

        // recurse
        if path.is_dir() {
            walk_persist(&path, persist_paths)?;
        }
    }

    Ok(())
}

fn main() {
    let impermanence_json = dirs::state_dir()
        .expect("unable to get $XDG_STATE_HOME")
        .join("impermanence.json");

    let impermenance = serde_json::from_str::<ImpermanencePaths>(
        &std::fs::read_to_string(impermanence_json).expect("unable to read impermanence.json"),
    )
    .expect("unable to parse impermanence.json");

    let persist_paths = [impermenance.directories, impermenance.files].concat();
    for root in ["/persist", "/cache"] {
        walk_persist(&PathBuf::from(root), &persist_paths).unwrap_or_else(|e| {
            eprintln!("An error has occured: {e}");
            std::process::exit(1);
        });
    }
}
