use clap::{CommandFactory, Parser};
use common::{
    is_hyprland, is_umbriel,
    umbriel::{UmbrielMonitor, UmbrielWindow},
};
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
        let focused = Client::get_active()?.unwrap_or_else(|| {
            eprintln!("No focused window.");
            std::process::exit(0);
        });
        let windows = Clients::get()?;
        let matching_windows = windows
            .iter()
            .filter(|client| client.class == focused.class)
            // sort by workspace then coordinates
            .sorted_by_key(|client| (client.workspace.id, client.at))
            .map(|client| &client.address)
            .collect_vec();

        let active_idx = matching_windows
            .iter()
            .position(|&addr| addr == &focused.address)
            .expect("focused window not found");

        let target = target_window(active_idx, &matching_windows, &direction);

        let lua_dispatch = format!(r#"hl.dsp.focus({{ window = "address:{target}" }})"#);
        execute::command_args!("hyprctl", "dispatch", lua_dispatch)
            .execute()
            .expect("failed to execute hl.dsp.focus");
    }

    if is_umbriel() {
        let focused = UmbrielWindow::focused().unwrap_or_else(|| {
            eprintln!("No focused window.");
            std::process::exit(0);
        });

        let mon_names: Vec<_> = UmbrielMonitor::all()
            .iter()
            .map(|mon| mon.name.to_string())
            .collect();

        let windows = UmbrielWindow::all();
        let matching_windows = windows
            .iter()
            .filter(|win| win.app_id == focused.app_id)
            .sorted_by_key(|win| {
                if let Some((mon_name, wksp_idx)) = win.workspace.split_once(":") {
                    let mon_idx = mon_names
                        .iter()
                        .position(|name| name == mon_name)
                        .unwrap_or_default();

                    let wksp_idx: i32 = wksp_idx.parse().unwrap_or_default();
                    (format!("{:02}:{:02}", mon_idx, wksp_idx), win.x, win.y)
                } else {
                    (win.workspace.clone(), win.x, win.y)
                }
            })
            .map(|win| &win.id)
            .collect_vec();

        let active_idx = matching_windows
            .iter()
            .position(|&id| id == &focused.id)
            .expect("focused window not found");

        let target = target_window(active_idx, &matching_windows, &direction);

        execute::command_args!("umbriel", "msg", format!("window-focus-warp:{target}"))
            .execute()
            .expect("failed to execute window-focus-warp");
    }

    Ok(())
}
