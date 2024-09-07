use std::path::PathBuf;

mod picture;
mod rofi;
mod slurp;
mod video;

pub use picture::Screenshot;
pub use rofi::Rofi;
pub use slurp::SlurpGeom;
pub use video::Screencast;

pub fn create_parent_dirs(path: PathBuf) -> PathBuf {
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            std::fs::create_dir_all(parent).expect("failed to create parent directories");
        }
    }

    path
}

pub fn iso8601_filename() -> String {
    chrono::Local::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)
}
