use std::path::PathBuf;

mod picture;
mod slurp;
mod video;

pub use picture::Screenshot;
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
