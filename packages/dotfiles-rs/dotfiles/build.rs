use clap::CommandFactory;
use clap_mangen::Man;
use std::{env, fs, path::PathBuf};

#[path = "src/cli.rs"]
mod cli;

fn generate_man_pages() -> Result<(), Box<dyn std::error::Error>> {
    let man_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target/man");

    fs::create_dir_all(&man_dir)?;

    // man pages for each command
    for cmd in [
        cli::WmMonitorArgs::command(),
        cli::WmSameClassArgs::command(),
        cli::RofiMpvArgs::command(),
    ] {
        let mut buffer = Vec::default();

        Man::new(cmd.clone()).render(&mut buffer)?;

        fs::write(man_dir.join(format!("{}.1", cmd.get_name())), buffer)?;
    }

    Ok(())
}

fn main() {
    assert!(
        !(cfg!(feature = "hyprland") && cfg!(feature = "niri")),
        "Cannot enable both 'hyprland' and 'niri' features simultaneously"
    );

    if let Err(err) = generate_man_pages() {
        println!("cargo:warning=Error generating man pages: {err}");
    }
}
