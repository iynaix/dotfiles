use dotfiles_utils::{hypr, hypr_json, monitor::Monitor};
use execute::Execute;
use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;

fn get_hyprland_socket() -> String {
    #[derive(Deserialize, Debug)]
    struct HyprlandInstance {
        instance: String,
        time: i32,
    }

    let instances = hypr_json::<Vec<HyprlandInstance>>("instances");
    let youngest = instances
        .iter()
        .min_by_key(|i| i.time)
        .expect("no hyprland instances running");
    format!("/tmp/hypr/{}/.socket2.sock", youngest.instance)
}

fn is_nstack() -> bool {
    #[derive(Deserialize, Debug)]
    struct HyprlandOption {
        str: String,
    }

    let opt = hypr_json::<HyprlandOption>("getoption general:layout");
    opt.str == "nstack"
}

fn set_workspace_orientation(workspace: &str, is_desktop: bool, nstack: bool) {
    if !is_desktop {
        return;
    }

    let wksp = workspace.replace(" silent", "");
    let (mon, _) = Monitor::by_workspace(&wksp);

    hypr(["layoutmsg", mon.orientation()]);

    // set nstack stacks
    if nstack {
        hypr(["layoutmsg", "setstackcount", &mon.stacks().to_string()]);
    }
}

fn main() {
    let is_desktop = gethostname::gethostname()
        .to_str()
        .unwrap_or_default()
        .ends_with("desktop");
    let nstack = is_nstack();

    let socket_path = get_hyprland_socket();
    let socket = UnixStream::connect(socket_path).expect("hyprland ipc socket not found");

    let reader = BufReader::new(socket);
    for line in reader.lines() {
        let line = line.unwrap_or_default();

        let (ev, ev_args) = line
            .split_once(">>")
            .expect("could not parse hyprland event");
        let ev_args: Vec<String> = ev_args
            .split(',')
            .map(std::string::ToString::to_string)
            .collect();

        // println!("{ev} ---- {ev_args:?}");

        match ev {
            // different handling for desktop and laptops is done within hypr-monitors
            "monitoradded" => {
                execute::command!("hypr-monitors")
                    .execute()
                    .expect("failed to run hypr-monitors");
            }
            "monitorremoved" => {
                if is_desktop {
                    let rearranged_workspaces = Monitor::rearranged_workspaces();
                    // focus desktop with the most workspaces
                    let (mon_to_focus, _) = rearranged_workspaces
                        .iter()
                        .max_by_key(|(_, wksps)| wksps.len())
                        .expect("no workspaces found");
                    hypr(["focusmonitor", mon_to_focus]);
                }
            }
            "openwindow" | "movewindow" => {
                let workspace = &ev_args[1];
                set_workspace_orientation(workspace, is_desktop, nstack);
            }
            _ => {
                // enable for debugging
                // println!("unhandled event: {ev} {ev_args:?}");
            }
        }
    }
}
