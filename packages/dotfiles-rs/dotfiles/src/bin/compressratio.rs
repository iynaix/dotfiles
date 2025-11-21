use std::{fs, os::linux::fs::MetadataExt, path::Path};

fn apparent_size(file_path: &Path) -> std::io::Result<u64> {
    let metadata = fs::metadata(file_path)?;
    // .len() returns the logical size of the file in bytes (the apparent size)
    Ok(metadata.len())
}

fn actual_size(file_path: &Path) -> std::io::Result<u64> {
    let metadata = fs::metadata(file_path)?;
    Ok(metadata.st_blocks() * 512)
}

fn main() {
    if std::env::args().len() != 2 {
        eprintln!("Usage: compressratio <file>");
        return;
    }

    let fp = std::env::args().nth(1).unwrap_or_else(|| {
        eprintln!("No file provided");
        std::process::exit(1);
    });
    let path = Path::new(&fp);

    let apparent = apparent_size(path).unwrap_or_else(|e| {
        eprintln!("Error getting apparent size: {e}");
        std::process::exit(1);
    });

    let actual = actual_size(path).unwrap_or_else(|e| {
        eprintln!("Error getting actual size: {e}");
        std::process::exit(1);
    });

    println!("Apparent size: {apparent}");
    println!("Actual size: {actual}");
    println!("Compression ratio: {:.2}", apparent as f64 / actual as f64);
}
