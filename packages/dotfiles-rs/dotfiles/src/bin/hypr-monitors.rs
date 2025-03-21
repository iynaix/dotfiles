use clap::Parser;
use dotfiles::{cli::HyprMonitorArgs, monitors::hypr_monitors};

fn main() {
    let args = HyprMonitorArgs::parse();

    hypr_monitors(args);
}
