use clap::Parser;
use dotfiles_utils::{cli::WaifuFetchArgs, full_path, nixinfo::NixInfo};
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

fn create_image(nix_info: &NixInfo, args: &WaifuFetchArgs) -> String {
    let logo = &nix_info.logo;
    let hexless = &nix_info.colors;
    let c4 = hexless.get("color4").expect("invalid color");
    let c6 = hexless.get("color6").expect("invalid color");

    let output_dir = full_path("~/.cache/waifufetch");
    std::fs::create_dir_all(&output_dir).expect("failed to create output dir");

    let output = full_path(format!(
        "{}/{}-{}.png",
        &output_dir
            .to_str()
            .expect("could not convert output dir to str"),
        c4,
        c6
    ));
    let output = output
        .to_str()
        .expect("could not convert output dir to str");

    let magick_args = [
        logo, // replace color 1
        "-fuzz", "10%", "-fill", c4, "-opaque", "#5278c3", // replace color 2
        "-fuzz", "10%", "-fill", c6, "-opaque", "#7fbae4",
    ];

    let image_size = args.size.unwrap_or(400);

    Command::new("magick")
        .args(magick_args)
        .args(["-resize", format!("{image_size}x{image_size}").as_str()])
        .arg(output)
        .status()
        .expect("failed to execute magick");

    output.to_string()
}

fn waifufetch(nix_info: &NixInfo, args: &WaifuFetchArgs) {
    let img = create_image(nix_info, args);

    let mut fastfetch = Command::new("fastfetch");

    // handle ascii logos
    if args.filled {
        fastfetch.args(["--logo", "nixos"]);
    } else if args.hollow {
        fastfetch.args(["--logo", "nixos_old_small"]);
    } else {
        // ghostty supports kitty image protocol
        fastfetch.args(["--kitty-direct", &img]);
    }

    fastfetch.args(["--config", "neofetch"]);

    fastfetch.status().expect("failed to execute fastfetch");
}

fn main() {
    let args = WaifuFetchArgs::parse();

    let nix_info = NixInfo::after();

    // initial display of waifufetch
    waifufetch(&nix_info, &args);

    // not showing waifu, no need to wait for signal
    if args.filled || args.hollow {
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
                    println!("received SIGUSR2");

                    let nix_info = NixInfo::after();
                    waifufetch(&nix_info, &args);
                }
                _ => unreachable!(),
            }
        }
    });

    loop {
        thread::sleep(Duration::from_millis(200));
    }
}
