use crate::cli::{BackupArgs, RemoteArgs};
use common::{full_path, wallpaper};
use execute::Execute;
use std::{path::Path, process::Stdio};

pub fn backup(args: BackupArgs) {
    let target = args.target.unwrap_or_else(|| full_path("/media/6TBRED"));

    execute::command_args!(
        "rsync",
        "-aP",
        "--delete",
        "--no-links",
        &wallpaper::dir(),
        &target
    )
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .execute_output()
    .expect("failed to backup wallpapers");

    // update rclip database
    #[cfg(feature = "rclip")]
    execute::command_args!("rclip", "--filepath-only", "cat")
        .current_dir(wallpaper::dir())
        .stdout(Stdio::null())
        .execute_output()
        // don't care about it erroring out
        .ok();
}

fn rsync(
    path: &Path,
    user: &str,
    remote_host: &str,
) -> Result<std::process::Output, std::io::Error> {
    // NOTE: trailing slash is important
    let path_str = format!("{}/", path.display());

    execute::command_args!("rsync", "-aP", "--delete", "--no-links", "--mkpath")
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .arg(&path_str)
        .arg(format!("{user}@{remote_host}:{path_str}"))
        .execute_output()
}

pub fn remote(args: RemoteArgs) {
    let user = whoami::username();
    let remote_host = args.hostname.unwrap_or_else(|| "framework".to_string());

    // backup to default location before syncing with remote
    backup(BackupArgs { target: None });

    rsync(&wallpaper::dir(), &user, &remote_host).expect("failed to sync wallpapers");

    // sync rclip database
    let rclip_db = dirs::data_dir()
        .expect("unable to get $XDG_DATA_HOME")
        .join("rclip");
    rsync(&rclip_db, &user, &remote_host).expect("failed to sync rclip database");
}
