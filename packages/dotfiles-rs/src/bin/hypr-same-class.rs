use clap::{CommandFactory, Parser, ValueEnum};
use dotfiles::{generate_completions, ShellCompletion};
use hyprland::dispatch;
use hyprland::{
    data::{Client, Clients},
    dispatch::{Dispatch, DispatchType, WindowIdentifier::Address},
    shared::{HyprData, HyprDataActiveOptional},
};

#[derive(ValueEnum, Clone, Debug)]
pub enum Direction {
    Next,
    Prev,
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr-same-class",
    about = "Focus next / prev window of same class"
)]
pub struct HyprSameClassArgs {
    #[arg(value_enum)]
    pub direction: Option<Direction>,

    #[arg(
        long,
        value_enum,
        help = "type of shell completion to generate",
        hide = true,
        exclusive = true
    )]
    pub generate: Option<ShellCompletion>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = HyprSameClassArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("hypr-monitors", &mut HyprSameClassArgs::command(), &shell);
        std::process::exit(0);
    }

    if args.direction.is_none() {
        eprintln!("No direction specified. Use 'next' or 'prev'.");
        std::process::exit(1);
    }

    let active = Client::get_active()?.expect("no active window");
    let clients = Clients::get()?;
    let mut same_class: Vec<_> = clients
        .iter()
        .filter(|client| client.class == active.class)
        .collect();

    // sort by workspace then coordinates
    same_class.sort_by_key(|client| (client.workspace.id, client.at));
    let addresses: Vec<_> = same_class
        .into_iter()
        .map(|client| &client.address)
        .collect();

    let active_idx = addresses
        .iter()
        .position(|&addr| addr == &active.address)
        .expect("active window not found");

    let new_idx: usize = match args
        .direction
        .unwrap_or_else(|| panic!("no direction specified"))
    {
        Direction::Next => (active_idx + 1) % addresses.len(),
        Direction::Prev => (active_idx - 1 + addresses.len()) % addresses.len(),
    };

    dispatch!(FocusWindow, Address(addresses[new_idx].clone()))?;

    Ok(())
}
