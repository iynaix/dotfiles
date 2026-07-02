{ lib, self, ... }:
{
  flake.modules.nixos.wm =
    { config, ... }:
    let
      inherit (config.custom.constants) dots projects;
      inherit (config.custom.hardware) monitors;
      termExec = cmd: "ghostty -e ${cmd}";
    in
    {
      custom = {
        programs.niri.settings = {
          binds = {
            # show hotkey overlay
            # "Mod+Shift+Slash".show-hotkey-overlay = _: {};

            "Mod+Return".spawn-sh = "ghostty";
            "Mod+Shift+Return".spawn-sh = "noctalia-ipc launcher toggle";
            "Mod+BackSpace" = _: {
              props = {
                repeat = false;
              };
              content = {
                close-window = _: { };
              };
            };

            "Mod+E".spawn-sh = "nemo ${config.hj.directory}/Downloads";
            "Mod+Shift+E".spawn-sh = termExec "yazi ${config.hj.directory}/Downloads";
            # background process to workaround a race condition that causes helium to only open sometimes
            "Mod+W".spawn-sh = "helium --profile-directory=Default &";
            "Mod+Shift+W".spawn-sh = "helium --profile-directory=Default --incognito &";
            "Mod+V".spawn-sh = "emacsclient -c";
            "Mod+Shift+V".spawn-sh = "noctalia-ipc plugin:projects toggle";
            "Mod+period".spawn-sh = ''focus-or-run "dotfiles - VSCodium" "codium ${dots}"'';
            "Mod+Shift+period".spawn = ''focus-or-run "nixpkgs - VSCodium" "codium ${projects}/nixpkgs"'';

            # exit niri
            "Alt+F4".quit = _: { };
            "Ctrl+Alt+Delete".spawn-sh = "noctalia-ipc sessionMenu toggle";

            # toggle the bar
            "Mod+A".spawn-sh = "noctalia-ipc bar toggle";

            # restart noctalia
            "Mod+Shift+A".spawn-sh = "noctalia-reload";

            # clipboard history
            "Mod+Ctrl+V".spawn-sh = "noctalia-ipc launcher clipboard";

            # notification history
            "Mod+N".spawn-sh = "noctalia-ipc notifications toggleHistory";

            # TODO: reset monitors?
            # "CTRL_SHIFT, Escape, exec, niri-monitors"

            # Open/close the Overview: a zoomed-out view of workspaces and windows.
            # You can also move the mouse into the top-left hot corner,
            # or do a four-finger swipe up on a touchpad.
            "Mod+O" = _: {
              props = {
                repeat = false;
              };
              content = {
                toggle-overview = _: { };
              };
            };

            "Mod+H".focus-column-or-monitor-left = _: { };
            "Mod+J".focus-window-or-workspace-down = _: { };
            "Mod+K".focus-window-or-workspace-up = _: { };
            "Mod+L".focus-column-or-monitor-right = _: { };

            "Mod+Shift+H".move-column-left-or-to-monitor-left = _: { };
            "Mod+Shift+J".move-window-down-or-to-workspace-down = _: { };
            "Mod+Shift+K".move-window-up-or-to-workspace-up = _: { };
            "Mod+Shift+L".move-column-right-or-to-monitor-right = _: { };

            "Mod+Home".focus-column-first = _: { };
            "Mod+End".focus-column-last = _: { };
            "Mod+Shift+Home".move-column-to-first = _: { };
            "Mod+Shift+End".move-column-to-last = _: { };

            "Mod+Left".focus-monitor-left = _: { };
            "Mod+Down".focus-monitor-down = _: { };
            "Mod+Up".focus-monitor-up = _: { };
            "Mod+Right".focus-monitor-right = _: { };

            "Mod+Shift+Left".move-column-to-monitor-left = _: { };
            "Mod+Shift+Down".move-column-to-monitor-down = _: { };
            "Mod+Shift+Up".move-column-to-monitor-up = _: { };
            "Mod+Shift+Right".move-column-to-monitor-right = _: { };

            # toggle between prev and current windows
            "Mod+grave".focus-window-previous = _: { };

            # Switches focus between the current and the previous workspace.
            "Mod+Tab".focus-workspace-previous = _: { };

            # picture in picture mode
            "Mod+P".spawn-sh = "wm-pip";

            # The following binds move the focused window in and out of a column.
            # If the window is alone, they will consume it into the nearby column to the side.
            # If the window is already in a column, they will expel it out.
            "Mod+BracketLeft".consume-or-expel-window-left = _: { };
            "Mod+BracketRight".consume-or-expel-window-right = _: { };

            "Mod+R".switch-preset-column-width = _: { };
            "Mod+Shift+R".switch-preset-window-height = _: { };
            "Mod+Ctrl+R".spawn-sh = lib.getExe' config.custom.programs.dotfiles-rs "niri-resize-workspace";
            # full maximize
            "Mod+Z".maximize-column = _: { };
            "Mod+F".fullscreen-window = _: { };
            # Expand the focused column to space not taken up by other fully visible columns.
            # Makes the column"fill the rest of the space".
            "Mod+Shift+F".expand-column-to-available-width = _: { };

            "Mod+C".center-column = _: { };

            # Center all fully visible columns on screen.
            "Mod+Ctrl+C".center-visible-columns = _: { };

            # Move the focused window between the floating and the tiling layout.
            "Mod+G".toggle-window-floating = _: { };
            # "Mod+Shift+V".switch-focus-between-floating-and-tiling = _: {};

            # Toggle tabbed column display mode.
            # Windows in this column will appear as vertical tabs,
            # rather than stacked on top of each other.
            "Mod+T".toggle-column-tabbed-display = _: { };

            "Mod+Apostrophe".spawn = "wallpaper rofi";
            # "Mod+Shift+Apostrophe".spawn-sh = "rofi-wallust-theme";
            "Alt+Apostrophe".spawn = "wallpaper history";

            # audio
            "XF86AudioLowerVolume" = _: {
              props = {
                allow-when-locked = true;
              };
              content = {
                spawn-sh = "pamixer -d 5";
              };
            };
            "XF86AudioRaiseVolume" = _: {
              props = {
                allow-when-locked = true;
              };
              content = {
                spawn-sh = "pamixer -i 5";
              };
            };
            "XF86AudioMute" = _: {
              props = {
                allow-when-locked = true;
              };
              content = {
                spawn-sh = "pamixer -t";
              };
            };

            # mouse bindings

            # having Mod + Scroll up / Down is impossible to control with trackball, so require Shift for workspaces
            "Mod+Shift+WheelScrollDown" = _: {
              props = {
                cooldown-ms = 150;
              };
              content = {
                focus-workspace-down = _: { };
              };
            };
            "Mod+Shift+WheelScrollUp" = _: {
              props = {
                cooldown-ms = 150;
              };
              content = {
                focus-workspace-up = _: { };
              };
            };

            "Mod+WheelScrollRight".focus-column-right-or-first = _: { };
            "Mod+WheelScrollLeft".focus-column-left-or-last = _: { };
          }
          # named workspace setup, dynamic workspaces are urgh
          // lib.mergeAttrsList (
            lib.flatten (
              (self.libCustom.mapWorkspaces (
                { workspace, key, ... }:
                [
                  {
                    # Switch workspaces with mainMod + [0-9]
                    "Mod+${key}".focus-workspace = toString workspace;
                    # Move active window to a workspace with mainMod + SHIFT + [0-9]
                    "Mod+Shift+${key}".move-window-to-workspace = toString workspace;
                  }
                ]
              ))
                monitors
            )
          );
        };
      };
    };
}
