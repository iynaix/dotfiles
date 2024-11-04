use common::{
    filename,
    wallpaper::{self, filter_images},
    CommandUtf8,
};
use execute::Execute;
use std::process::Stdio;

use clap::Args;

#[allow(clippy::module_name_repetitions)]
#[derive(Args, Debug, PartialEq, Eq)]
pub struct SearchArgs {
    #[arg(
        short,
        long,
        name = "TOP",
        default_value = "50",
        help = "Number of top results to display"
    )]
    top: u32,

    #[arg(name = "QUERY", help = "Search query")]
    query: String,
}

pub fn search(args: SearchArgs) {
    let wall_dir = wallpaper::dir();

    let lower_query = args.query.to_lowercase();
    let mut all_results: Vec<_> = filter_images(&wall_dir)
        .filter(|path| filename(path).to_lowercase().contains(&lower_query))
        .collect();

    let query = args.query;
    let mut cmd = execute::command_args!("rclip", "--filepath-only");

    cmd.current_dir(wall_dir);
    cmd.arg("--top").arg(args.top.to_string());
    cmd.arg(query);

    let rclip_results = cmd
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .execute_stdout_lines();

    all_results.extend(rclip_results);
    execute::command_args!("pqiv", "--additional-from-stdin")
        .execute_input_output(all_results.join("\n").as_bytes())
        .expect("failed to run pqiv");
}
