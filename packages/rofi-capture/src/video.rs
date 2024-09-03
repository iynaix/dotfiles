use std::{io::Write, path::PathBuf};

use crate::{create_parent_dirs, SlurpGeom};
use dotfiles::{iso8601_filename, monitor::Monitor, rofi::Rofi};
use execute::{command, Execute};

pub struct Screencast;

#[derive(Default)]
struct WfRecorder {
    monitor: String,
    output: PathBuf,
    filter: String,
    duration: Option<u64>,
}

impl WfRecorder {
    pub fn new(monitor: &str, output: PathBuf) -> Self {
        Self {
            monitor: monitor.to_string(),
            output,
            ..Default::default()
        }
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

    fn lock_path() -> PathBuf {
        dirs::runtime_dir()
            .expect("could not get $XDG_RUNTIME_DIR")
            .join("rofi-capture.lock")
    }

    pub fn stop() -> bool {
        // kill all wf-recorder processes
        let mut sys = sysinfo::System::new();
        sys.refresh_processes(sysinfo::ProcessesToUpdate::All);

        let mut is_killed = false;
        for process in sys.processes_by_exact_name("wf-recorder".as_ref()) {
            is_killed = true;
            process.kill_with(sysinfo::Signal::Interrupt);
        }

        // check lock file and close the process within if it exists
        let lock_file = Self::lock_path();
        if let Ok(pid) = std::fs::read_to_string(&lock_file) {
            if let Ok(pid) = pid.trim().parse::<u32>() {
                if let Some(process) = sys.process(sysinfo::Pid::from_u32(pid)) {
                    // stop the recording by wf-recorder
                    for process in sys.processes_by_exact_name("wf-recorder".as_ref()) {
                        process.kill_with(sysinfo::Signal::Interrupt);
                    }

                    // kill the previous instance of rofi-capture
                    process.kill_with(sysinfo::Signal::Interrupt);

                    // delete the lock file
                    std::fs::remove_file(&lock_file).expect("Failed to delete lock file");
                    return true;
                }
            }
        }

        is_killed
    }

    pub fn record(self) {
        let mut wfrecorder = command!("wf-recorder");

        if !self.filter.is_empty() {
            wfrecorder.arg("--filter").arg(&self.filter);
        }

        if let Ok(child) = wfrecorder
            .arg("--output")
            .arg(&self.monitor)
            .arg("--overwrite")
            .arg("-f")
            .arg(&self.output)
            .spawn()
        {
            // duration provied, recording will stop by itself so no lock file is needed
            if let Some(duration) = self.duration {
                std::thread::sleep(std::time::Duration::from_secs(duration));

                Self::stop();
            } else {
                let mut lock = std::fs::OpenOptions::new()
                    .write(true)
                    .create(true)
                    .truncate(true)
                    .open(Self::lock_path())
                    .expect("failed to create rofi-capture.lock");

                writeln!(lock, "{}", child.id()).expect("failed to write to rofi-capture.lock");
            }
        } else {
            panic!("failed to execute wf-recorder");
        }
    }
}

impl Screencast {
    pub fn output_path(filename: Option<PathBuf>) -> PathBuf {
        create_parent_dirs(filename.unwrap_or_else(|| {
            dirs::video_dir()
                .expect("could not get $XDG_VIDEOS_DIR")
                .join(format!("Screencasts/{}.mp4", iso8601_filename()))
        }))
    }

    fn capture(mon: &str, filter: &str, output_path: PathBuf) {
        // copy the video file to clipboard
        command!("wl-copy")
            .arg("--type")
            .arg("text/uri-list")
            .execute_input(&format!("file://{}", output_path.display()))
            .expect("failed to copy video to clipboard");

        // small delay before recording
        std::thread::sleep(std::time::Duration::from_millis(500));

        WfRecorder::new(mon, output_path).filter(filter).record();
    }

    pub fn selection(output_path: PathBuf) {
        let (mon, filter) = SlurpGeom::prompt().to_ffmpeg_geom();
        Self::capture(&mon, &filter, output_path);
    }

    pub fn monitor(output_path: PathBuf) {
        Self::capture(&Monitor::focused().name, "", output_path);
    }

    pub fn stop() -> bool {
        WfRecorder::stop()
    }

    pub fn rofi(filename: &Option<PathBuf>) {
        let output_path = Self::output_path(filename.clone());

        let rofi = Rofi::new("rofi-menu-noinput.rasi", &["Selection", "Monitor"]);

        let sel = rofi.run();
        match sel.as_str() {
            "Monitor" => Self::monitor(output_path),
            "Selection" => Self::selection(output_path),
            "All" => unimplemented!("Capturing of all outputs has not been implemented for video"),
            "" => {
                eprintln!("No rofi selection was made.");
                std::process::exit(1);
            }
            _ => unimplemented!("Invalid rofi selection"),
        };
    }
}
