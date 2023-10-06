use dotfiles_utils::{cmd, hypr, hypr_json, Monitor, Workspace};
use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;

struct Globals {
    is_desktop: bool,
    nstack: bool,
}

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

fn set_workspace_orientation(workspace: String, globals: &Globals) {
    if !globals.is_desktop {
        return;
    }

    let wksp = Workspace::by_name(workspace.replace(" silent", ""));
    if !wksp.is_empty() {
        let mon = wksp.monitor();

        hypr(&["layoutmsg", mon.orientation()]);

        // set nstack stacks
        if globals.nstack {
            hypr(&["layoutmsg", "setstackcount", &mon.stacks().to_string()]);
        }
    }
}

fn main() {
    let globals = Globals {
        is_desktop: gethostname::gethostname()
            .to_str()
            .unwrap_or_default()
            .ends_with("desktop"),
        nstack: is_nstack(),
    };

    let socket_path = get_hyprland_socket();
    let socket = UnixStream::connect(socket_path).expect("hyprland ipc socket not found");

    let reader = BufReader::new(socket);
    for line in reader.lines() {
        let line = line.unwrap_or_default();

        let (ev, ev_args) = line.split_once(">>").unwrap();
        let ev_args: Vec<String> = ev_args.split(',').map(|s| s.to_string()).collect();

        // println!("{ev} ---- {ev_args:?}");

        match ev {
            "monitoradded" => {
                if globals.is_desktop {
                    cmd(["hypr-monitors"])
                }
            }
            "monitorremoved" => {
                if globals.is_desktop {
                    let rearranged_workspaces = Monitor::rearranged_workspaces();
                    // focus desktop with the most workspaces
                    let (mon_to_focus, _) = rearranged_workspaces
                        .iter()
                        .max_by_key(|(_, wksps)| wksps.len())
                        .unwrap();
                    hypr(&["focusmonitor", mon_to_focus])
                }
            }
            "openwindow" => {
                let workspace = &ev_args[1];
                set_workspace_orientation(workspace.to_string(), &globals);
            }
            "movewindow" => {
                let workspace = &ev_args[1];
                set_workspace_orientation(workspace.to_string(), &globals);
            }
            _ => {
                // enable for debugging
                // println!("unhandled event: {ev} {ev_args:?}");
            }
        }
    }
}
