use clap::{CommandFactory, Parser};
use dotfiles::{
    cli::{Direction, WmSameClassArgs},
    generate_completions,
};
use itertools::Itertools;

// gets the target window given the direction
fn target_window<T>(active_idx: usize, matching: &[T], direction: &Direction) -> T
where
    T: Clone,
{
    let new_idx = match direction {
        Direction::Next => (active_idx + 1) % matching.len(),
        Direction::Prev => (active_idx - 1 + matching.len()) % matching.len(),
    };

    matching[new_idx].clone()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = WmSameClassArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("wm-same-class", &mut WmSameClassArgs::command(), &shell);
        std::process::exit(0);
    }

    let Some(direction) = args.direction else {
        eprintln!("No direction specified. Use 'next' or 'prev'.");
        std::process::exit(1);
    };

    #[cfg(feature = "hyprland")]
    {
        use hyprland::dispatch;
        use hyprland::{
            data::{Client, Clients},
            dispatch::{Dispatch, DispatchType, WindowIdentifier::Address},
            shared::{HyprData, HyprDataActiveOptional},
        };

        let active = Client::get_active()?.expect("no active window");
        let windows = Clients::get()?;
        let matching_windows = windows
            .iter()
            .filter(|client| client.class == active.class)
            // sort by workspace then coordinates
            .sorted_by_key(|client| (client.workspace.id, client.at))
            .map(|client| &client.address)
            .collect_vec();

        let active_idx = matching_windows
            .iter()
            .position(|&addr| addr == &active.address)
            .expect("active window not found");

        let target = target_window(active_idx, &matching_windows, &direction);

        dispatch!(FocusWindow, Address(target.clone()))?;
    }

    #[cfg(feature = "niri")]
    {
        use niri_ipc::{Action, Request, Response, socket::Socket};

        let mut socket = Socket::connect().expect("failed to connect to niri socket");

        let active = match socket
            .send(Request::FocusedWindow)
            .expect("failed to send FocusedWindow request to niri")
        {
            Ok(Response::FocusedWindow(Some(active))) => active,
            Ok(Response::FocusedWindow(None)) => {
                eprintln!("No active window found.");
                std::process::exit(0);
            }
            _ => panic!("invalid reply for FocusedWindow"),
        };

        let Ok(Response::Windows(windows)) = socket
            .send(Request::Windows)
            .expect("failed to send Windows request to niri")
        else {
            panic!("invalid reply for Windows");
        };

        let matching_windows = windows
            .iter()
            .filter(|w| w.app_id == active.app_id)
            .sorted_by_key(|w| w.workspace_id)
            .map(|w| w.id)
            .collect_vec();

        let active_idx = matching_windows
            .iter()
            .position(|&id| id == active.id)
            .expect("active window not found");

        let target = target_window(active_idx, &matching_windows, &direction);

        socket.send(Request::Action(Action::FocusWindow { id: target }))??;
    }

    Ok(())
}
