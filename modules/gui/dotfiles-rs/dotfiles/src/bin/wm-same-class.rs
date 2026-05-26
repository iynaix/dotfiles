use clap::{CommandFactory, Parser};
use common::is_hyprland;
use dotfiles::{
    cli::{Direction, WmSameClassArgs},
    generate_completions,
};
use execute::Execute;
use hyprland::{
    data::{Client, Clients},
    shared::{HyprData, HyprDataActiveOptional},
};
use itertools::Itertools;

// gets the target window given the direction
fn target_window<T>(active_idx: usize, matching: &[T], direction: &Direction) -> T
where
    T: Clone,
{
    let new_idx = match direction {
        Direction::Next => (active_idx + 1) % matching.len(),
        Direction::Prev => (active_idx + matching.len() - 1) % matching.len(),
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

    if is_hyprland() {
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

        let lua_dispatch = format!(r#"hl.dsp.focus({{ window = "address:{target}" }})"#);
        execute::command_args!("hyprctl", "dispatch", lua_dispatch)
            .execute()
            .expect("failed to execute pqiv");
    }

    Ok(())
}
