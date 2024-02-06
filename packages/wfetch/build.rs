use std::ffi::OsString;

use clap::{Command, CommandFactory};
use clap_complete::{
    generate_to,
    shells::{Bash, Fish, Zsh},
};

include!("src/cli.rs");

pub fn generate_completions(mut cli: Command, outdir: &OsString) -> Result<(), std::io::Error> {
    let cmd_name = cli.get_name().to_string();
    generate_to(Bash, &mut cli, &cmd_name, outdir)?;
    generate_to(Zsh, &mut cli, &cmd_name, outdir)?;
    generate_to(Fish, &mut cli, &cmd_name, outdir)?;

    Ok(())
}

fn main() -> Result<(), std::io::Error> {
    let outdir = match std::env::var_os("OUT_DIR") {
        None => return Ok(()),
        Some(outdir) => outdir,
    };

    generate_completions(WFetchArgs::command(), &outdir)?;

    Ok(())
}
