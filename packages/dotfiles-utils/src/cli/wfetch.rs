use clap::Parser;
use dotfiles_utils::{cli::WaifuFetchArgs, fetch::create_fastfetch_config, nixinfo::NixInfo};
use signal_hook::{
    consts::{SIGINT, SIGUSR2},
    iterator::Signals,
};
use std::process::Command;
use std::{
    io::{self, Write},
    thread,
    time::Duration,
};

fn wfetch(nix_info: &NixInfo, args: &WaifuFetchArgs) {
    let mut fastfetch = Command::new("fastfetch");

    let config_jsonc = "/tmp/wfetch.jsonc";
    create_fastfetch_config(args, nix_info, config_jsonc);
    fastfetch.args(["--config", config_jsonc]);

    fastfetch.status().expect("failed to execute fastfetch");
}

fn main() {
    let args = WaifuFetchArgs::parse();

    let nix_info = NixInfo::after();

    // initial display of wfetch
    wfetch(&nix_info, &args);

    // not showing waifu / wallpaper, no need to wait for signal
    if args.no_socket || (!args.waifu && !args.wallpaper) {
        std::process::exit(0);
    }

    // hide terminal cursor
    print!("\x1B[?25l");
    io::stdout().flush().expect("Failed to flush stdout");

    // handle SIGUSR2 to update colors
    // https://rust-cli.github.io/book/in-depth/signals.html#handling-other-types-of-signals
    let mut signals = Signals::new([SIGINT, SIGUSR2]).expect("failed to register signals");

    thread::spawn(move || {
        for sig in signals.forever() {
            match sig {
                SIGINT => {
                    // restore terminal cursor
                    print!("\x1B[?25h");
                    io::stdout().flush().expect("Failed to flush stdout");
                    std::process::exit(0);
                }
                SIGUSR2 => {
                    let nix_info = NixInfo::after();
                    wfetch(&nix_info, &args);
                }
                _ => unreachable!(),
            }
        }
    });

    loop {
        thread::sleep(Duration::from_millis(200));
    }
}
