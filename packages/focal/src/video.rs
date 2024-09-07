use serde::{Deserialize, Serialize};
use std::path::PathBuf;

use crate::{Rofi, SlurpGeom};
use execute::{command, command_args, Execute};
use hyprland::{data::Monitor, shared::HyprDataActive};

#[derive(Serialize, Deserialize)]
struct LockFile {
    pid: u32,
    child: u32,
    video: PathBuf,
}

impl LockFile {
    fn path() -> PathBuf {
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("focal.lock")
    }

    fn write(&self) -> std::io::Result<()> {
        let content = serde_json::to_string(&self).expect("failed to serialize focal.lock");
        std::fs::write(Self::path(), content)
    }

    fn read() -> std::io::Result<Self> {
        let content = std::fs::read_to_string(Self::path())?;
        serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))
    }

    fn remove() {
        std::fs::remove_file(Self::path()).expect("failed to delete focal.lock");
    }
}

#[derive(Default)]
struct WfRecorder {
    monitor: String,
    audio: bool,
    notify: bool,
    video: PathBuf,
    filter: String,
    duration: Option<u64>,
}

impl WfRecorder {
    pub fn new(monitor: &str, video: PathBuf) -> Self {
        Self {
            monitor: monitor.to_string(),
            video,
            ..Default::default()
        }
    }

    pub fn audio(mut self, audio: bool) -> Self {
        self.audio = audio;
        self
    }

    pub fn filter(mut self, filter: &str) -> Self {
        self.filter = filter.to_string();
        self
    }

    #[allow(dead_code)]
    pub const fn duration(mut self, seconds: u64) -> Self {
        self.duration = Some(seconds);
        self
    }

    pub fn stop(notify: bool) -> bool {
        // kill all wf-recorder processes
        let mut sys = sysinfo::System::new();
        sys.refresh_processes(sysinfo::ProcessesToUpdate::All);

        let mut is_killed = false;
        for process in sys.processes_by_exact_name("wf-recorder".as_ref()) {
            is_killed = true;
            process.kill_with(sysinfo::Signal::Interrupt);
        }

        // check lock file and close the process within if it exists
        if let Ok(LockFile { pid, child, video }) = LockFile::read() {
            if let Some(child_process) = sys.process(sysinfo::Pid::from_u32(child)) {
                // stop any wf-recorder processes
                child_process.kill_with(sysinfo::Signal::Interrupt);
                for wf_process in sys.processes_by_exact_name("wf-recorder".as_ref()) {
                    wf_process.kill_with(sysinfo::Signal::Interrupt);
                }

                // kill previous instance of focal
                if let Some(prev_process) = sys.process(sysinfo::Pid::from_u32(pid)) {
                    prev_process.kill_with(sysinfo::Signal::Interrupt);
                }

                LockFile::remove();

                // show notification with the video thumbnail
                if notify {
                    Self::notify(&video);
                }

                return true;
            }
        }

        is_killed
    }

    pub fn record(self) {
        let mut wfrecorder = command!("wf-recorder");

        if !self.filter.is_empty() {
            wfrecorder.arg("--filter").arg(&self.filter);
        }

        if self.audio {
            wfrecorder.arg("--audio");
        }

        if let Ok(child) = wfrecorder
            .arg("--output")
            .arg(&self.monitor)
            .arg("--overwrite")
            .arg("-f")
            .arg(&self.video)
            .spawn()
        {
            // duration provied, recording will stop by itself so no lock file is needed
            if let Some(duration) = self.duration {
                std::thread::sleep(std::time::Duration::from_secs(duration));

                Self::stop(self.notify);
            } else {
                let lock = LockFile {
                    pid: std::process::id(),
                    child: child.id(),
                    video: self.video.clone(),
                };
                lock.write().expect("failed to write to focal.lock");
            }
        } else {
            panic!("failed to execute wf-recorder");
        }
    }

    fn notify(video: &PathBuf) {
        let thumb_path = PathBuf::from("/tmp/focal-thumbnail.jpg");

        if thumb_path.exists() {
            std::fs::remove_file(&thumb_path).expect("failed to remove notification thumbnail");
        }

        command!("ffmpeg")
            .arg("-i")
            .arg(video)
            // from 3s in the video
            .arg("-ss")
            .arg("00:00:03.000")
            .arg("-vframes")
            .arg("1")
            .arg("-s")
            .arg("128x72")
            .arg(&thumb_path)
            .execute()
            .expect("failed to create notification thumbnail");

        // show notifcation with the video thumbnail
        command_args!("notify-send", "-t", "3000", "-a", "focal")
            .arg(format!("Video captured to {}", video.display()))
            .arg("-i")
            .arg(&thumb_path)
            .execute()
            .expect("Failed to send screencast notification");
    }
}

pub struct Screencast {
    pub delay: Option<u64>,
    pub audio: bool,
    pub output: PathBuf,
}

impl Screencast {
    fn capture(&self, mon: &str, filter: &str) {
        // copy the video file to clipboard
        command!("wl-copy")
            .arg("--type")
            .arg("text/uri-list")
            .execute_input(&format!("file://{}", self.output.display()))
            .expect("failed to copy video to clipboard");

        // small delay before recording
        std::thread::sleep(std::time::Duration::from_millis(500));

        WfRecorder::new(mon, self.output.clone())
            .audio(self.audio)
            .filter(filter)
            .record();
    }

    pub fn selection(&self) {
        let (mon, filter) = SlurpGeom::prompt().to_ffmpeg_geom();
        self.capture(&mon, &filter);
    }

    pub fn monitor(&self) {
        let focused = Monitor::get_active().expect("unable to get active monitor");
        self.capture(&focused.name, "");
    }

    pub fn stop(notify: bool) -> bool {
        WfRecorder::stop(notify)
    }

    pub fn rofi(&mut self, theme: &Option<PathBuf>) {
        let mut rofi = Rofi::new(&["Selection", "Monitor"]);

        if let Some(theme) = &theme {
            rofi = rofi.theme(theme.clone());
        }

        let (sel, exit_code) = rofi
            // for editing with swappy
            .arg("-kb-custom-1")
            .arg("Alt-a")
            .arg("-mesg")
            .arg("Audio can be recorded using Alt+a")
            .run();

        // custom keyboard code selected
        if !self.audio {
            self.audio = exit_code == 10;
        }

        match sel.as_str() {
            "Monitor" => {
                std::thread::sleep(std::time::Duration::from_secs(self.rofi_delay(theme)));
                self.monitor();
            }
            "Selection" => {
                std::thread::sleep(std::time::Duration::from_secs(self.rofi_delay(theme)));
                self.selection();
            }
            "All" => unimplemented!("Capturing of all outputs has not been implemented for video"),
            "" => {
                eprintln!("No rofi selection was made.");
                std::process::exit(1);
            }
            _ => unimplemented!("Invalid rofi selection"),
        };
    }

    /// prompts the user for delay using rofi if not provided as a cli flag
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
