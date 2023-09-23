use clap::{Parser, Subcommand};
use dotfiles_utils::{hypr, hypr_clients, ActiveWindow};

#[derive(Subcommand, Debug)]
enum Direction {
    Next,
    Prev,
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr_same_class",
    about = "Focus next / prev window of same class"
)]
struct Args {
    #[command(subcommand)]
    direction: Direction,
}

fn main() {
    let args = Args::parse();
    let active = ActiveWindow::new();

    let clients = hypr_clients();
    let mut same_class: Vec<_> = clients
        .iter()
        .filter(|client| client.class == active.class)
        .collect();

    // sort by workspace then coordinates
    same_class.sort_by_key(|client| (client.workspace.id, client.at));
    let addresses: Vec<&String> = same_class.iter().map(|client| &client.address).collect();

    let active_idx = addresses
        .iter()
        .position(|&addr| addr == &active.address)
        .unwrap();

    let new_idx: usize = match args.direction {
        Direction::Next => active_idx + addresses.len() + 1,
        Direction::Prev => active_idx + addresses.len() - 1,
    };

    hypr(&[
        "focuswindow",
        format!("address:{}", addresses[new_idx % addresses.len()]).as_str(),
    ]);
}
