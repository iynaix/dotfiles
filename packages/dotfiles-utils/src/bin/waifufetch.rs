use clap::Parser;
use dotfiles_utils::NixInfo;
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

fn create_image(nix_info: &NixInfo) -> String {
    let logo = &nix_info.neofetch.logo;
    let hexless = &nix_info.colors;
    let c4 = hexless.get("color4").expect("invalid color");
    let c6 = hexless.get("color6").expect("invalid color");

    let output = format!("/tmp/waifufetch-{}-{}.png", c4, c6);

    let magick_args = [
        logo, // replace color 1
        "-fuzz", "10%", "-fill", c4, "-opaque", "#5278c3", // replace color 2
        "-fuzz", "10%", "-fill", c6, "-opaque", "#7fbae4", &output,
    ];

    Command::new("magick")
        .args(magick_args)
        .status()
        .expect("failed to execute magick");

    output
}

fn waifufetch(nix_info: &NixInfo) {
    let img = create_image(nix_info);
    let neofetch_config = &nix_info.neofetch.conf;

    // assume kitty by default
    let backend = if std::env::var("TERM").unwrap_or("xterm-kitty".to_string()) == "xterm-kitty" {
        "--kitty"
    } else {
        "--sixel"
    };

    let neofetch_args = [backend, &img, "--config", neofetch_config];

    Command::new("neofetch")
        .args(neofetch_args)
        .status()
        .expect("failed to execute neofetch");
}

#[derive(Parser, Debug)]
#[command(name = "waifufetch", about = "Neofetch, but more waifu")]
struct Args {
    #[arg(long, action, help = "prints path to generated image")]
    image: bool,
}

fn main() {
    let args = Args::parse();

    let nix_info = NixInfo::from_cache();

    if args.image {
        println!("{}", create_image(&nix_info));
        std::process::exit(0)
    }

    // initial display of waifufetch
    waifufetch(&nix_info);

    // hide terminal cursor
    print!("\x1B[?25l");
    io::stdout().flush().expect("Failed to flush stdout");

    // handle SIGUSR2 to update colors
    // https://rust-cli.github.io/book/in-depth/signals.html#handling-other-types-of-signals
    let mut signals = Signals::new([SIGINT, SIGUSR2]).unwrap();

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

                    let nix_info = NixInfo::from_cache();
                    waifufetch(&nix_info);
                }
                _ => unreachable!(),
            }
        }
    });

    loop {
        thread::sleep(Duration::from_millis(200));
    }
}
