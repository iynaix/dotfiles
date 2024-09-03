use dotfiles::{monitor::Monitor, Client};
use execute::{command_args, Execute};
use std::{fmt, process::Stdio};

#[derive(Debug)]
pub struct SlurpGeomParseError {
    message: String,
}

impl SlurpGeomParseError {
    fn new(msg: &str) -> Self {
        Self {
            message: msg.to_string(),
        }
    }
}

impl fmt::Display for SlurpGeomParseError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.message)
    }
}

#[derive(Debug, Clone, Copy)]
pub struct SlurpGeom {
    w: i32,
    h: i32,
    x: i32,
    y: i32,
}

impl fmt::Display for SlurpGeom {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{},{} {}x{}", self.x, self.y, self.w, self.h)
    }
}

impl std::str::FromStr for SlurpGeom {
    type Err = SlurpGeomParseError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let re = regex::Regex::new(r"[,\sx]+").expect("Failed to create regex for slurp geom");

        let parts: Vec<_> = re
            .split(s)
            .map(|s| s.parse::<i32>().expect("Failed to parse slurp"))
            .collect();

        if parts.len() != 4 {
            return Err(SlurpGeomParseError::new("Slurp geom must have 4 parts"));
        }

        Ok(Self {
            x: parts[0],
            y: parts[1],
            w: parts[2],
            h: parts[3],
        })
    }
}

impl SlurpGeom {
    pub fn to_ffmpeg_geom(self) -> (String, String) {
        let Self { x, y, w, h } = self;
        let monitors = Monitor::monitors();

        let mon = monitors
            .into_iter()
            .find(|m| x >= m.x && x <= m.x + m.width && y >= m.y && y <= m.y + m.height)
            .unwrap_or_else(|| {
                panic!("No monitor found for slurp region");
            });

        // get coordinates relative to monitor
        let (x, y) = (x - mon.x, y - mon.y);
        let round2 = |n: i32| {
            if n % 2 == 1 {
                n - 1
            } else {
                n
            }
        };

        // h264 requires the width and height to be even
        let final_w = round2(h);
        let final_h = round2(w);

        let filter = match mon.transform {
            0 => format!("crop=w={w}:h={h}:x={x}:y={y}"),
            // clockwise
            1 => {
                let final_y = mon.width - x - w;
                let final_x = y;
                format!("crop=w={final_w}:h={final_h}:x={final_x}:y={final_y}, transpose=1")
            }
            // anti-clockwise
            3 => {
                let final_x = mon.width - y - h;
                let final_y = x;
                format!("crop=w={final_w}:h={final_h}:x={final_x}:y={final_y}, transpose=2")
            }
            _ => {
                panic!("Unknown monitor transform: {}", mon.transform);
            }
        };

        (mon.name, filter)
    }

    pub fn prompt() -> Self {
        let active_wksps = Monitor::active_workspaces();
        let active_wksps: Vec<_> = active_wksps.values().collect();

        let windows = Client::clients();
        let window_geoms: Vec<_> = windows
            .iter()
            .filter_map(|win| {
                if active_wksps.contains(&&win.workspace.id) {
                    Some(Self {
                        x: win.at.0,
                        y: win.at.1,
                        w: win.size.0,
                        h: win.size.1,
                    })
                } else {
                    None
                }
            })
            .collect();

        let slurp_geoms = window_geoms
            .iter()
            .map(std::string::ToString::to_string)
            .collect::<Vec<_>>()
            .join("\n");

        let sel = command_args!("slurp")
            .stdout(Stdio::piped())
            .execute_input_output(&slurp_geoms)
            .expect("failed to execute slurp");

        let sel = std::str::from_utf8(&sel.stdout)
            .expect("failed to parse utf8 from slurp selection")
            .strip_suffix("\n")
            .unwrap_or_default()
            .to_string();

        if sel.is_empty() {
            eprintln!("No slurp selection made");
            std::process::exit(1);
        };

        window_geoms
            .into_iter()
            .find(|geom| geom.to_string() == sel)
            .unwrap_or_else(|| sel.parse().expect("Failed to parse slurp selection"))
    }
}
