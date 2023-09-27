use clap::{Parser, Subcommand};
use dotfiles_utils::{hypr, ActiveWindow, Client};

#[derive(Subcommand, Debug)]
enum Direction {
    Next,
    Prev,
}

#[derive(Parser, Debug)]
#[command(
    name = "hypr-same-class",
    about = "Focus next / prev window of same class"
)]
struct Args {
    #[command(subcommand)]
    direction: Direction,
}

fn main() {
    let args = Args::parse();
    let active = ActiveWindow::new();
    let mut same_class = Client::filter_class(active.class);

    // sort by workspace then coordinates
    same_class.sort_by_key(|client| (client.workspace.id, client.at));
    let addresses: Vec<&String> = same_class.iter().map(|client| &client.address).collect();

    let active_idx = addresses
        .iter()
        .position(|&addr| addr == &active.address)
        .unwrap();

    let new_idx: usize = match args.direction {
        Direction::Next => (active_idx + 1) % addresses.len(),
        Direction::Prev => (active_idx - 1 + addresses.len()) % addresses.len(),
    };

    hypr(&["focuswindow", &format!("address:{}", addresses[new_idx])]);
}
