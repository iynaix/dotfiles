use clap::CommandFactory;
use clap_mangen::Man;
use std::{env, fs, path::PathBuf};

#[path = "src/cli.rs"]
mod cli;

fn generate_man_pages() -> Result<(), Box<dyn std::error::Error>> {
    let cmd = cli::WallpaperArgs::command();
    let man_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target/man");

    fs::create_dir_all(&man_dir)?;

    // main wallpaper man page
    let mut buffer = Vec::default();
    Man::new(cmd.clone()).render(&mut buffer)?;
    fs::write(man_dir.join("wallpaper.1"), buffer)?;

    // subcommand man pages
    for subcmd in cmd.get_subcommands().filter(|c| !c.is_hide_set()) {
        let subcmd_name = format!("wallpaper-{}", subcmd.get_name());
        let subcmd = subcmd.clone().name(&subcmd_name);

        let mut buffer = Vec::default();

        Man::new(subcmd)
            .title(subcmd_name.to_uppercase())
            .render(&mut buffer)?;

        fs::write(man_dir.join(subcmd_name + ".1"), buffer)?;
    }

    Ok(())
}

fn main() {
    if let Err(err) = generate_man_pages() {
        println!("cargo:warning=Error generating man pages: {err}");
    }
}
