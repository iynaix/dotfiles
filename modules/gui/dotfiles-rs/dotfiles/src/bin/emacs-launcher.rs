use clap::Parser;
use color_eyre::eyre::Result;
use common::{is_umbriel, umbriel::UmbrielWindow};
use dotfiles::cli::EmacsLauncherArgs;
use execute::Execute;
use std::process::Command;

fn execute_emacs_command(elisp: &str) -> Result<()> {
    let cmd = format!(r"(progn (select-frame-set-input-focus (selected-frame)) {elisp})");

    println!("{cmd}");

    Command::new("emacsclient")
        .args(["-n", "-e", &cmd])
        .status()?;

    Ok(())
}

fn main() -> Result<()> {
    let args = EmacsLauncherArgs::parse();

    // switch to emacs window
    if is_umbriel() {
        for win in UmbrielWindow::all()? {
            if win.app_id == "emacs" {
                execute::command_args!("umbriel", "msg", format!("window-focus:{}", win.id))
                    .execute()?;
            }
        }
    }

    std::thread::sleep(std::time::Duration::from_millis(500));

    execute_emacs_command(&args.elisp)
}
