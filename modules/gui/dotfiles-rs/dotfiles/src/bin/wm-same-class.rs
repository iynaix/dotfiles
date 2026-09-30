use clap::{CommandFactory, Parser};
use color_eyre::eyre::{OptionExt, Result};
use common::{
    is_umbriel,
    umbriel::{UmbrielMonitor, UmbrielWindow},
};
use dotfiles::{
    cli::{Direction, WmSameClassArgs},
    generate_completions,
};
use execute::Execute;
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

fn main() -> Result<()> {
    let args = WmSameClassArgs::parse();

    // print shell completions
    if let Some(shell) = args.generate {
        generate_completions("wm-same-class", &mut WmSameClassArgs::command(), &shell);
        return Ok(());
    }

    let Some(direction) = args.direction else {
        eprintln!("No direction specified. Use 'next' or 'prev'.");
        std::process::exit(1);
    };

    if is_umbriel() {
        let focused = UmbrielWindow::focused()?;

        let mon_names: Vec<_> = UmbrielMonitor::all()?
            .iter()
            .map(|mon| mon.name.clone())
            .collect();

        let windows = UmbrielWindow::all()?;
        let matching_windows = windows
            .iter()
            .filter(|win| win.app_id == focused.app_id)
            .sorted_by_key(|win| {
                if let Some((mon_name, wksp_idx)) = win.workspace.split_once(':') {
                    let mon_idx = mon_names
                        .iter()
                        .position(|name| name == mon_name)
                        .unwrap_or_default();

                    let wksp_idx: i32 = wksp_idx.parse().unwrap_or_default();
                    (format!("{mon_idx:02}:{wksp_idx:02}"), win.x, win.y)
                } else {
                    (win.workspace.clone(), win.x, win.y)
                }
            })
            .map(|win| &win.id)
            .collect_vec();

        let active_idx = matching_windows
            .iter()
            .position(|&id| id == &focused.id)
            .ok_or_eyre("No focused window")?;

        let target = target_window(active_idx, &matching_windows, &direction);

        execute::command_args!("umbriel", "msg", format!("window-focus-warp:{target}"))
            .execute()?;
    }

    Ok(())
}
