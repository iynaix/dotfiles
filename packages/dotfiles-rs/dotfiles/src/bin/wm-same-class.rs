use clap::{CommandFactory, Parser};
use dotfiles::{
    cli::{Direction, WmSameClassArgs},
    generate_completions,
};
use hyprland::dispatch;
use hyprland::{
    data::{Client, Clients},
    dispatch::{Dispatch, DispatchType, WindowIdentifier::Address},
    shared::{HyprData, HyprDataActiveOptional},
};
use itertools::Itertools;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = WmSameClassArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("wm-same-class", &mut WmSameClassArgs::command(), &shell);
        std::process::exit(0);
    }

    if args.direction.is_none() {
        eprintln!("No direction specified. Use 'next' or 'prev'.");
        std::process::exit(1);
    }

    let active = Client::get_active()?.expect("no active window");
    let clients = Clients::get()?;
    let addresses = clients
        .iter()
        .filter(|client| client.class == active.class)
        // sort by workspace then coordinates
        .sorted_by_key(|client| (client.workspace.id, client.at))
        .map(|client| &client.address)
        .collect_vec();

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
