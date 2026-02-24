use crate::cli::SearchArgs;
use common::{
    CommandUtf8, filename,
    wallpaper::{self, filter_images},
};
use execute::Execute;
use std::process::Stdio;

pub fn search(args: SearchArgs) {
    let wall_dir = wallpaper::dir();

    let mut all_results = if args.query.len() == 1 {
        let lower_query = args.query[0].to_lowercase();
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
    cmd.args(query);

    let rclip_results = cmd
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .execute_stdout_lines()
        .unwrap_or_default();

    all_results.extend(rclip_results);
    execute::command_args!("pqiv", "--additional-from-stdin")
        .execute_input_output(all_results.join("\n").as_bytes())
        .expect("failed to run pqiv");
}
