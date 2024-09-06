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

pub struct Screenshot {
    pub delay: Option<u64>,
    pub edit: Option<bool>,
    pub output: PathBuf,
}

impl Screenshot {
    pub fn new(filename: Option<PathBuf>, delay: Option<u64>, edit: Option<bool>) -> Self {
        let output = create_parent_dirs(filename.unwrap_or_else(|| {
            dirs::picture_dir()
                .expect("could not get $XDG_PICTURES_DIR")
                .join(format!("Screenshots/{}.png", iso8601_filename()))
        }));

        Self {
            delay,
            edit,
            output,
        }
    }

    fn capture(&self, monitor: &str, geometry: &str) {
        // small delay before capture
        std::thread::sleep(std::time::Duration::from_millis(500));

        Grim::new(self.output.clone())
            .geometry(geometry)
            .monitor(monitor)
            .capture();
    }

    pub fn monitor(&self) {
        self.capture(&Monitor::focused().name, "");
    }

    pub fn selection(&self) {
        self.capture("", &SlurpGeom::prompt().to_string());
    }

    pub fn all(&self) {
        let mut w = 0;
        let mut h = 0;
        for mon in Monitor::monitors() {
            w = w.max(mon.x + mon.width);
            h = h.max(mon.y + mon.height);
        }

        self.capture("", &format!("0,0 {w}x{h}"));
    }

    pub fn edit(&self) {
        command!("swappy")
            .arg("--file")
            .arg(self.output.clone())
            .arg("--output-file")
            .arg(self.output.clone())
            .execute()
            .expect("Failed to edit screenshot with swappy");
    }

    pub fn rofi(&self, theme: &Option<PathBuf>) {
        let mut rofi = Rofi::new(&["Selection", "Monitor", "All"]);

        if let Some(theme) = theme {
            rofi = rofi.theme(theme.clone());
        }

        let (sel, exit_code) = rofi
            // for editing with swappy
            .arg("-kb-custom-1")
            .arg("Alt-e")
            .arg("-mesg")
            .arg("Screenshots can be edited with swappy by using Alt+e")
            .run();

        // Alt-e is exit code 10
        let do_edit = self.edit.unwrap_or(exit_code == 10);

        match sel.as_str() {
            "Selection" => {
                // delay is pointless for selection
                self.selection()
            }
            "Monitor" => {
                std::thread::sleep(std::time::Duration::from_secs(self.rofi_delay(theme)));
                self.monitor()
            }
            "All" => {
                std::thread::sleep(std::time::Duration::from_secs(self.rofi_delay(theme)));
                self.all()
            }
            "" => {
                eprintln!("No capture area selection was made.");
                std::process::exit(1);
            }
            _ => unimplemented!("Invalid rofi selection"),
        };

        if do_edit {
            self.edit();
        }
    }

    pub fn rofi_delay(&self, theme: &Option<PathBuf>) -> u64 {
        let delay_options = ["0", "3", "5"];

        let mut rofi = Rofi::new(&delay_options);
        if let Some(theme) = theme {
            rofi = rofi.theme(theme.clone());
        }

        let (sel, _) = rofi.run();

        if sel.is_empty() {
            eprintln!("No delay selection was made.");
            std::process::exit(1);
        }

        sel.parse::<u64>().expect("Invalid delay specified")
    }
}
