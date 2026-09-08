use std::process::Stdio;

use execute::{Execute, command_args};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct UmbrielMonitor {
    pub enabled: bool,
    pub name: String,
    pub modes: Vec<UmbrielMonitorMode>,
    pub scale: f32,
    pub transform: String,
    pub position: UmbrielMonitorPosition,
}

#[derive(Debug, Deserialize)]
pub struct UmbrielMonitorPosition {
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Deserialize, Clone)]
pub struct UmbrielMonitorMode {
    pub current: bool,
    pub height: i32,
    pub width: i32,
}

#[derive(Debug, Deserialize)]
pub struct UmbrielWorkspace {
    pub index: i32,
    pub active: bool,
    pub focused: bool,
    pub output: String,
}

#[derive(Debug, Deserialize)]
pub struct UmbrielWindow {
    pub active: bool,
    pub focused: bool,
    pub app_id: String,
    pub workspace: String,
    pub id: String,
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
    pub floating: bool,
}

impl UmbrielWorkspace {
    pub fn all() -> Vec<Self> {
        let umbriel_cmd = execute::command_args!("umbriel", "workspaces", "--json")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("failed to run umbriel workspaces");
        let umbriel_json =
            String::from_utf8(umbriel_cmd.stdout).expect("invalid utf8 from umbriel workspaces");

        serde_json::from_str(&umbriel_json).expect("failed to parse json")
    }

    pub fn focused() -> Option<Self> {
        Self::all().into_iter().find(|wksp| wksp.focused)
    }
}

impl UmbrielMonitor {
    pub fn all() -> Vec<Self> {
        let umbriel_cmd = command_args!("umbriel", "outputs", "--json")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("failed to run umbriel outputs");
        let umbriel_json =
            String::from_utf8(umbriel_cmd.stdout).expect("invalid utf8 from umbriel outputs");

        serde_json::from_str(&umbriel_json).expect("failed to parse json")
    }

    pub fn focused() -> Option<Self> {
        // get focused workspace, then get focused monitor from there
        UmbrielWorkspace::all()
            .into_iter()
            .find(|wksp| wksp.focused)
            .and_then(|wksp| Self::all().into_iter().find(|mon| mon.name == wksp.output))
    }

    pub fn current_mode(&self) -> Option<UmbrielMonitorMode> {
        self.modes.iter().find(|mode| mode.current).cloned()
    }

    pub fn is_vertical(&self) -> bool {
        self.transform.contains("90") || self.transform.contains("270")
    }
}

impl UmbrielWindow {
    pub fn all() -> Vec<Self> {
        let umbriel_cmd = command_args!("umbriel", "windows", "--json")
            .stdout(Stdio::piped())
            .execute_output()
            .expect("failed to run umbriel windows");
        let umbriel_json =
            String::from_utf8(umbriel_cmd.stdout).expect("invalid utf8 from umbriel windows");

        serde_json::from_str(&umbriel_json).expect("failed to parse json")
    }

    pub fn focused() -> Option<Self> {
        // get focused workspace, then get focused monitor from there
        UmbrielWindow::all()
            .into_iter()
            .find(|win| win.focused && win.active)
    }
}
