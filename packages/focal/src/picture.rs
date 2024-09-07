use std::{path::PathBuf, process::Stdio};

use crate::{Rofi, SlurpGeom};
use execute::{command, command_args, Execute};
use hyprland::{
    data::{Monitor, Monitors},
    shared::{HyprData, HyprDataActive},
};

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

    pub fn capture(self, notify: bool) {
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

        // show a notification
        if notify {
            command_args!("notify-send", "-t", "3000", "-a", "focal")
                .arg(format!("Screenshot captured to {}", self.output.display()))
                .arg("-i")
                .arg(&self.output)
                .execute()
                .expect("Failed to send screenshot notification");
        }
    }
}

pub struct Screenshot {
    pub delay: Option<u64>,
    pub edit: bool,
    pub notify: bool,
    pub ocr: bool,
    pub output: PathBuf,
}

impl Screenshot {
    fn capture(&self, monitor: &str, geometry: &str) {
        if !self.ocr {
            // copy the image file to clipboard
            command!("wl-copy")
                .arg("--type")
                .arg("text/uri-list")
                .execute_input(&format!("file://{}", self.output.display()))
                .expect("failed to copy image to clipboard");
        }

        // small delay before capture
        std::thread::sleep(std::time::Duration::from_millis(500));

        Grim::new(self.output.clone())
            .geometry(geometry)
            .monitor(monitor)
            .capture(self.notify);

        if self.ocr {
            self.ocr();
        } else if self.edit {
            self.edit();
        }
    }

    pub fn monitor(&self) {
        let focused = Monitor::get_active().expect("unable to get active monitor");
        self.capture(&focused.name, "");
    }

    pub fn selection(&self) {
        self.capture("", &SlurpGeom::prompt().to_string());
    }

    pub fn all(&self) {
        let mut w = 0;
        let mut h = 0;
        for mon in Monitors::get().expect("unable to get monitors").iter() {
            w = w.max(mon.x + mon.width as i32);
            h = h.max(mon.y + mon.height as i32);
        }

        self.capture("", &format!("0,0 {w}x{h}"));
    }

    fn edit(&self) {
        command!("swappy")
            .arg("--file")
            .arg(self.output.clone())
            .arg("--output-file")
            .arg(self.output.clone())
            .execute()
            .expect("Failed to edit screenshot with swappy");
    }

    fn ocr(&self) {
        let output = command!("tesseract")
            .arg(&self.output)
            .arg("-")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("Failed to run tesseract");

        command!("wl-copy")
            .stdout(Stdio::piped())
            .execute_input(&output.stdout)
            .expect("unable to copy ocr text");
    }

    pub fn rofi(&mut self, theme: &Option<PathBuf>) {
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

        // custom keyboard code selected
        self.edit = exit_code == 10;

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
                eprintln!("No capture selection was made.");
                std::process::exit(1);
            }
            _ => unimplemented!("Invalid rofi selection"),
        };
    }

    fn rofi_delay(&self, theme: &Option<PathBuf>) -> u64 {
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
