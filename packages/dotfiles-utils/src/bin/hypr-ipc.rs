use dotfiles_utils::nixinfo::NixInfo;
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

fn log(msg: &str) {
    use std::io::Write;

    // open /tmp/hypr/hypr-ipc.log for writing
    let mut log = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open("/tmp/hypr-ipc.log")
        .expect("could not open log file");

    writeln!(log, "{msg}").expect("could not write to log file");
}

fn is_nstack() -> bool {
    #[derive(Deserialize, Debug)]
    struct HyprlandOption {
        str: String,
    }

    let opt = hypr_json::<HyprlandOption>("getoption general:layout");
    opt.str == "nstack"
}

/// set random split ratio to prevent oled burn in
fn set_split_ratio(mon: &Monitor, nstack: bool) {
    if mon.is_ultrawide() {
        let split_ratio = rand::random::<f32>().mul_add(0.1, 0.4);
        let keyword_path = if nstack {
            "plugin:nstack:layout:mfact"
        } else {
            "master:mfact"
        };

        log(&format!("setting split ratio: {split_ratio}"));

        execute::command_args!("hyprctl", "keyword", keyword_path, split_ratio.to_string())
            .execute()
            .expect("unable to set mfact");
    }
}

/// set workspace orientation and nstack stacks for vertical / ultrawide
fn set_workspace_orientation(mon: &Monitor, nstack: bool) {
    hypr(["layoutmsg", mon.orientation()]);

    // set nstack stacks
    if nstack {
        hypr(["layoutmsg", "setstackcount", &mon.stacks().to_string()]);
    }
}

fn main() {
    let is_desktop = NixInfo::before().host == "desktop";
    let nstack = is_nstack();

    let socket_path = get_hyprland_socket();
    let socket = UnixStream::connect(socket_path).expect("hyprland ipc socket not found");

    let reader = BufReader::new(socket);
    for line in reader.lines() {
        let line = line.unwrap_or_default();

        let (ev, ev_args) = line
            .split_once(">>")
            .unwrap_or_else(|| panic!("could not parse hyprland event from {line}"));
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
                log(&format!("{ev} {ev_args:?}"));

                if is_desktop {
                    let wksp = &ev_args[1].replace(" silent", "");
                    let (mon, _) = Monitor::by_workspace(wksp);

                    set_split_ratio(&mon, nstack);
                    set_workspace_orientation(&mon, nstack);
                }
            }
            _ => {
                // enable for debugging
                // println!("unhandled event: {ev} {ev_args:?}");
            }
        }
    }
}
