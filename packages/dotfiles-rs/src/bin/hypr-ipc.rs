use dotfiles::nixinfo::NixInfo;
use dotfiles::Client;
use dotfiles::{hypr_json, monitor::Monitor};
use execute::Execute;
use hyprland::keyword::Keyword;
use rand::Rng;
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
    Keyword::set(keyword_path, split_ratio.to_string()).expect("unable to set mfact");
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

    // set a random gap for desktop
    if is_desktop {
        // random gap between 4 and 8
        let gap = rand::thread_rng().gen_range(4..=8).to_string();

        Keyword::set("general:gaps_in", gap.clone()).expect("failed to set gaps");
        Keyword::set("general:gaps_out", gap).expect("failed to set gaps");
    };

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
                // single monitor in config; is laptop
                if NixInfo::before().monitors.len() == 1 {
                    // pass new monitor to rofi monitors for mirroring
                    let new_mon = ev_args.first().expect("no monitor name found");
                    execute::command!("hypr-monitors")
                        .arg("--rofi")
                        .arg(new_mon)
                        .execute()
                        .expect("failed to run rofi-monitors");
                } else {
                    // desktop, redistribute workspaces
                    execute::command!("hypr-monitors")
                        .execute()
                        .expect("failed to run hypr-monitors");
                }
            }
            "monitorremoved" => {
                // redistribute workspaces
                execute::command!("hypr-monitors")
                    .execute()
                    .expect("failed to run hypr-monitors");
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
