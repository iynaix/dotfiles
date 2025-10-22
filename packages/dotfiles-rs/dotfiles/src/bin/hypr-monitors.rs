use clap::Parser;
use dotfiles::{cli::WmMonitorArgs, monitors::hypr_monitors};

fn main() {
    let args = WmMonitorArgs::parse();

    hypr_monitors(args);
}
