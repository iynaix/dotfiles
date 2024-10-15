use std::{
    fs,
    io::{BufRead, BufReader},
    path::{Path, PathBuf},
};

fn walk_persist(dir: &Path, persist_paths: &Vec<String>) -> std::io::Result<()> {
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
    let fp = fs::File::open(
        dirs::state_dir()
            .expect("unable to get XDG_STATE_HOME")
            .join("impermanence.txt"),
    )
    .expect("could not read impermanence.txt, generate it with nix?");
    let persist_paths: Vec<String> = BufReader::new(fp)
        .lines()
        .map_while(Result::ok)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .collect();

    for root in ["/persist", "/cache"] {
        walk_persist(&PathBuf::from(root), &persist_paths).unwrap_or_else(|e| {
            eprintln!("An error has occured: {e}");
            std::process::exit(1);
        });
    }
}
