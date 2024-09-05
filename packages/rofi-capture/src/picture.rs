use std::path::PathBuf;

use crate::{create_parent_dirs, SlurpGeom};
use dotfiles::{iso8601_filename, monitor::Monitor, rofi::Rofi};
use execute::{command, command_args, Execute};

#[derive(Default)]
struct Grim {
    monitor: String,
    geometry: String,
    output: PathBuf,
}

impl Grim {
    pub fn new(output: PathBuf) -> Self {
        Self {
            output,
            ..Default::default()
        }
    }

    pub fn geometry(mut self, geometry: &str) -> Self {
        self.geometry = geometry.to_string();
        self
    }

    pub fn monitor(mut self, monitor: &str) -> Self {
        self.monitor = monitor.to_string();
        self
    }

    pub fn capture(self) {
        let mut grim = command!("grim");

        if !self.monitor.is_empty() {
            grim.arg("-o").arg(self.monitor);
        }

        if !self.geometry.is_empty() {
            grim.arg("-g").arg(self.geometry);
        }

        grim.arg(&self.output)
            .execute()
            .expect("unable to execute grim");

        // show a notifcation
        command_args!("notify-send", "-t", "3000", "-a", "rofi-capture")
            .arg(format!("Screenshot captured to {}", self.output.display()))
            .arg("-i")
            .arg(&self.output)
            .execute()
            .expect("Failed to send screenshot notification");
    }
}

pub struct Screenshot;

impl Screenshot {
    pub fn output_path(filename: Option<PathBuf>) -> PathBuf {
        create_parent_dirs(filename.unwrap_or_else(|| {
            dirs::picture_dir()
                .expect("could not get $XDG_PICTURES_DIR")
                .join(format!("Screenshots/{}.png", iso8601_filename()))
        }))
    }

    fn capture(monitor: &str, geometry: &str, output_path: PathBuf) {
        // small delay before capture
        std::thread::sleep(std::time::Duration::from_millis(500));

        Grim::new(output_path.clone())
            .geometry(geometry)
            .monitor(monitor)
            .capture();
    }

    pub fn monitor(output_path: PathBuf) {
        Self::capture(&Monitor::focused().name, "", output_path);
    }

    pub fn selection(output_path: PathBuf) {
        Self::capture("", &SlurpGeom::prompt().to_string(), output_path);
    }

    pub fn all(output_path: PathBuf) {
        let mut w = 0;
        let mut h = 0;
        for mon in Monitor::monitors() {
            w = w.max(mon.x + mon.width);
            h = h.max(mon.y + mon.height);
        }

        Self::capture("", &format!("0,0 {w}x{h}"), output_path);
    }

    pub fn rofi(filename: &Option<PathBuf>) {
        let output_path = Self::output_path(filename.clone());

        let rofi = Rofi::new("rofi-menu-noinput.rasi", &["Selection", "Monitor", "All"]);

        let sel = rofi.run();
        match sel.as_str() {
            "Monitor" => Self::monitor(output_path),
            "Selection" => Self::selection(output_path),
            "All" => Self::all(output_path),
            "" => {
                eprintln!("No rofi selection was made.");
                std::process::exit(1);
            }
            _ => unimplemented!("Invalid rofi selection"),
        };
    }
}
