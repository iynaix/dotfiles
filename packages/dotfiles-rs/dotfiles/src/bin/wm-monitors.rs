use clap::Parser;
use dotfiles::{cli::WmMonitorArgs, monitors::wm_monitors};

fn main() {
    let args = WmMonitorArgs::parse();

    wm_monitors(args);
}
