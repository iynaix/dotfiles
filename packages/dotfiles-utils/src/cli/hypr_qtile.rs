use clap::Parser;
use dotfiles_utils::{cli::HyprQtileArgs, hypr, monitor::Monitor, ActiveWindow};

fn main() {
    let args = HyprQtileArgs::parse();

    let target_workspace = args.workspace.to_string();
    let current_monitor = ActiveWindow::new().get_monitor();
    let (target_monitor, workspace_exists) = Monitor::by_workspace(target_workspace.clone());

    match workspace_exists {
        true => {
            hypr(["workspace", target_workspace.as_str()]);
            hypr([
                "swapactiveworkspaces",
                current_monitor.name.as_str(),
                target_monitor.name.as_str(),
            ]);
        }
        false => {
            hypr([
                "moveworkspacetomonitor",
                target_workspace.as_str(),
                target_monitor.id.to_string().as_str(),
            ]);
            hypr([
                "workspace",
                current_monitor.name.as_str(),
                target_workspace.as_str(),
            ]);
        }
    }
}
