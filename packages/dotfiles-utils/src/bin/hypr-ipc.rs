use dotfiles_utils::nixinfo::NixInfo;
use dotfiles_utils::Client;
use dotfiles_utils::{hypr, hypr_json, monitor::Monitor};
use execute::Execute;
use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;

fn get_hyprland_socket() -> PathBuf {
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

    dirs::runtime_dir()
        .expect("could not get $XDG_RUNTIME_DIR")
        .join("hypr")
        .join(&youngest.instance)
        .join(".socket2.sock")
}

#[allow(dead_code)]
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
fn set_split_ratio(nstack: bool, split_ratio: f32) {
    let keyword_path = if nstack {
        "plugin:nstack:layout:mfact"
    } else {
        "master:mfact"
    };

    // log(&format!("setting split ratio: {split_ratio}"));

    execute::command_args!("hyprctl", "keyword", keyword_path, split_ratio.to_string())
        .execute()
        .expect("unable to set mfact");
}

/// sets split ratio if there are 2 windows
fn split_for_workspace(wksp: &str, nstack: bool) {
    let wksp = &wksp.replace(" silent", "");
    let (mon, _) = Monitor::by_workspace(wksp);

    if !mon.is_oled() {
        return;
    }

    let wksp_id = wksp.parse().unwrap_or_default();
    let clients = Client::filter_workspace(wksp_id);

    // floating window, don't do anything
    if clients.iter().any(|c| c.floating) {
        return;
    }

    let num_windows = clients.len();
    let split_ratio = if num_windows == 2 {
        rand::random::<f32>().mul_add(0.1, 0.4)
    } else if nstack {
        0.0
    } else {
        0.5
    };

    set_split_ratio(nstack, split_ratio);
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
            "openwindow" => {
                // TODO: cannot resize tiled windows?
                /*
                if ev_args[2] == "mpv" {
                    if let Some(win) = Client::by_id(&ev_args[0]) {
                        let (mon, _) = Monitor::by_workspace(&ev_args[1]);

                        let (win_w, win_h) = win.size;
                        let is_full_width = mon.width - win_w < 60;
                        let is_full_height = mon.height - win_h < 60;

                        // single window, ignore
                        if is_full_width {
                            continue;
                        }

                        if is_full_height {
                            // resize width to fit 16:9 aspect ratio
                            let new_width = win_h * 16 / 9 - win_w;
                            let resize_params = format!("{new_width} {win_h}");

                            hypr(["focuswindow", &win.address]);
                            hypr(["resizeactive", &resize_params]);
                        }
                    }
                }
                */

                // only care about dynamic split ratios for oled
                if is_desktop {
                    split_for_workspace(&ev_args[1], nstack);
                }
            }
            "movewindow" => {
                // only care about dynamic split ratios for oled
                if is_desktop {
                    split_for_workspace(&ev_args[1], nstack);
                }
            }
            "closewindow" => {
                // only care about dynamic split ratios for oled
                if is_desktop {
                    if let Some(wksp_id) = Client::by_id(&ev_args[0]).map(|w| w.workspace.id) {
                        split_for_workspace(&wksp_id.to_string(), nstack);
                    }
                }
            }
            _ => {
                // enable for debugging
                // println!("unhandled event: {ev} {ev_args:?}");
            }
        }
    }
}
