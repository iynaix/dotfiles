use clap::Parser;
use color_eyre::eyre::Result;
use dotfiles::{cli::WmMonitorArgs, monitors::hypr_monitors};

fn main() -> Result<()> {
    let args = WmMonitorArgs::parse();

    hypr_monitors(args)
}
