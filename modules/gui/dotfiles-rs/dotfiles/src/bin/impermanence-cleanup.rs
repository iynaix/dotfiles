use color_eyre::eyre::{OptionExt, Result};
use std::{
    io::{BufRead, BufReader},
    path::{Path, PathBuf},
};

fn walk_persist(dir: &Path, persist_paths: &[String]) -> Result<()> {
    for entry in std::fs::read_dir(dir)? {
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

fn main() -> Result<()> {
    let impermanence_txt = dirs::state_dir()
        .ok_or_eyre("could not get XDG_STATE_DIR")?
        .join("impermanence.txt");

    let fp = std::fs::File::open(impermanence_txt)?;
    let persist_paths: Vec<_> = BufReader::new(fp).lines().map_while(Result::ok).collect();

    for root in ["/persist", "/cache"] {
        walk_persist(&PathBuf::from(root), &persist_paths)?;
    }

    Ok(())
}
