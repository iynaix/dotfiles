use clap::Parser;
use dotfiles_utils::{
    cli::{HyprSameClassArgs, HyprSameClassDirection},
    hypr, ActiveWindow, Client,
};

fn main() {
    let args = HyprSameClassArgs::parse();
    let active = ActiveWindow::new();
    let mut same_class = Client::filter_class(active.class.as_str());

    // sort by workspace then coordinates
    same_class.sort_by_key(|client| (client.workspace.id, client.at));
    let addresses: Vec<&String> = same_class.iter().map(|client| &client.address).collect();

    let active_idx = addresses
        .iter()
        .position(|&addr| addr == &active.address)
        .expect("active window not found");

    let new_idx: usize = match args.direction {
        HyprSameClassDirection::Next => (active_idx + 1) % addresses.len(),
        HyprSameClassDirection::Prev => (active_idx - 1 + addresses.len()) % addresses.len(),
    };

    hypr(["focuswindow", &format!("address:{}", addresses[new_idx])]);
}
