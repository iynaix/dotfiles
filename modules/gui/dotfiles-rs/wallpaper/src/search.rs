use crate::cli::SearchArgs;
use common::{
    CommandUtf8, filename,
    wallpaper::{self, filter_images},
};
use execute::Execute;
use std::process::Stdio;

pub fn search(args: SearchArgs) {
    let wall_dir = wallpaper::dir();

    let all_results = if args.query.contains(" ") {
        let lower_query = args.query.to_lowercase();
        filter_images(&wall_dir)
            .filter(|path| filename(path).to_lowercase().contains(&lower_query))
            .collect()
    } else {
        Vec::new()
    };

    let query = args.query;
    let mut cmd = execute::command_args!("rclip", "--filepath-only");

    cmd.current_dir(wall_dir);
    cmd.arg("--top").arg(args.top.to_string());
    cmd.arg(&query);

    let rclip_results = cmd
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .execute_stdout_lines()
        .unwrap_or_default();

    execute::command_args!(
        "swayimg",
        // show images in the given order
        "--execute",
        "swayimg.imagelist.order = \"none\""
    )
    .args(all_results)
    .args(rclip_results)
    .execute_output()
    .expect("failed to run swayimg");
}
