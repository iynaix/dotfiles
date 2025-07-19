{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    flatten
    getExe
    mergeAttrsList
    mkIf
    optionalAttrs
    ;
  inherit (config.custom) monitors;
  pamixerExe = getExe pkgs.pamixer;
  termExec =
    cmd:
    [
      (getExe config.custom.terminal.package)
      "-e"
    ]
    ++ (flatten cmd);
  rofiExe = getExe config.programs.rofi.package;
in
mkIf (config.custom.wm == "niri") {
  custom.shell.packages = {
    focus-or-run = {
      runtimeInputs = with pkgs; [
        config.wayland.windowManager.hyprland.package
        jq
      ];
      # $1 is string to search for in window title
      # $2 is the command to run if the window isn't found
      text = # sh
        ''
          id=$(niri msg -j windows | jq -r ".[] | select(.title | contains(\"$1\")) | .id")
          if [ -z "$id" ]; then
            eval "$2"
          else
            niri msg action focus-window --id "$id"
          fi
        '';
    };
  };

  programs.niri.settings = {
    binds =
      {
        # Most actions that you can bind here can also be invoked programmatically with
        # `niri msg action do-something`.

        # show hotkey overlay
        # "Mod+Shift+Slash".action.show-hotkey-overlay = { };

        "Mod+Return".action.spawn = getExe config.custom.terminal.package;
        "Mod+Shift+Return".action.spawn = [
          rofiExe
          "-show"
          "drun"
        ];
        "Mod+BackSpace" = {
          action.close-window = { };
          repeat = false;
        };

        "Mod+E".action.spawn = [
          "nemo"
          config.xdg.userDirs.download
        ];
        "Mod+Shift+E".action.spawn = termExec [
          "yazi"
          config.xdg.userDirs.download
        ];
        "Mod+W".action.spawn = getExe config.programs.chromium.package;
        "Mod+Shift+W".action.spawn = [
          (getExe config.programs.chromium.package)
          "--incognito"
        ];
        "Mod+V".action.spawn = termExec [ "nvim" ];
        "Mod+Shift+V".action.spawn = getExe pkgs.custom.shell.rofi-edit-proj;
        "Mod+period".action.spawn = [
          "focus-or-run"
          "dotfiles - VSCodium"
          "codium ${config.home.homeDirectory}/projects/dotfiles"
        ];
        "Mod+Shift+period".action.spawn = [
          "focus-or-run"
          "nixpkgs - VSCodium"
          "codium ${config.home.homeDirectory}/projects/nixpkgs"
        ];

        # exit niri
        "Alt+F4".action.quit = { };
        "Ctrl+Alt+Delete".action.spawn = getExe config.custom.rofi-power-menu.package;

        # clipboard history
        "Mod+Ctrl+V".action.spawn = getExe pkgs.custom.shell.rofi-clipboard-history;

        # TODO: reset monitors?
        # "CTRL_SHIFT, Escape, exec, niri-monitors"

        # Open/close the Overview: a zoomed-out view of workspaces and windows.
        # You can also move the mouse into the top-left hot corner,
        # or do a four-finger swipe up on a touchpad.
        "Mod+O" = {
          action.toggle-overview = { };
          repeat = false;
        };

        "Mod+H".action.focus-column-or-monitor-left = { };
        "Mod+J".action.focus-window-or-workspace-down = { };
        "Mod+K".action.focus-window-or-workspace-up = { };
        "Mod+L".action.focus-column-or-monitor-right = { };

        "Mod+Shift+H".action.move-column-left = { };
        "Mod+Shift+J".action.move-window-down-or-to-workspace-down = { };
        "Mod+Shift+K".action.move-window-up-or-to-workspace-up = { };
        "Mod+Shift+L".action.move-column-right = { };

        "Mod+Home".action.focus-column-first = { };
        "Mod+End".action.focus-column-last = { };
        "Mod+Shift+Home".action.move-column-to-first = { };
        "Mod+Shift+End".action.move-column-to-last = { };

        "Mod+Left".action.focus-monitor-left = { };
        "Mod+Down".action.focus-monitor-down = { };
        "Mod+Up".action.focus-monitor-up = { };
        "Mod+Right".action.focus-monitor-right = { };

        "Mod+Shift+Left".action.move-column-to-monitor-left = { };
        "Mod+Shift+Down".action.move-column-to-monitor-down = { };
        "Mod+Shift+Up".action.move-column-to-monitor-up = { };
        "Mod+Shift+Right".action.move-column-to-monitor-right = { };

        # classic alt tab in a workspace?
        "Alt+Tab".action.focus-column-right-or-first = { };
        "Alt+Shift+Tab".action.focus-column-left-or-last = { };

        # toggle between prev and current windows
        "Mod+grave".action.focus-window-previous = { };

        # Switches focus between the current and the previous workspace.
        "Mod+Tab".action.focus-workspace-previous = { };

        # switches to the next / previous window of the same class
        "Ctrl+Alt+Tab".action.spawn = [
          "wm-same-class"
          "next"
        ];
        "Ctrl+Alt+Shift+Tab".action.spawn = [
          "wm-same-class"
          "prev"
        ];

        # picture in picture mode
        "Mod+P".action.spawn = "wm-pip";

        # The following binds move the focused window in and out of a column.
        # If the window is alone, they will consume it into the nearby column to the side.
        # If the window is already in a column, they will expel it out.
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };

        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.switch-preset-window-height = { };
        "Mod+Ctrl+R".action.reset-window-height = { };
        # full maximize
        "Mod+Z".action.maximize-column = { };
        "Mod+F".action.fullscreen-window = { };
        # Expand the focused column to space not taken up by other fully visible columns.
        # Makes the column"fill the rest of the space".
        "Mod+Shift+F".action.expand-column-to-available-width = { };

        "Mod+C".action.center-column = { };

        # Center all fully visible columns on screen.
        "Mod+Ctrl+C".action.center-visible-columns = { };

        # Move the focused window between the floating and the tiling layout.
        "Mod+G".action.toggle-window-floating = { };
        # "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

        # Toggle tabbed column display mode.
        # Windows in this column will appear as vertical tabs,
        # rather than stacked on top of each other.
        "Mod+T".action.toggle-column-tabbed-display = { };

        "Mod+Apostrophe".action.spawn = [
          "wallpaper"
          "rofi"
        ];
        "Mod+Shift+Apostrophe".action.spawn = "rofi-wallust-theme";
        "Alt+Apostrophe".action.spawn = [
          "wallpaper"
          "history"
        ];

        # audio
        "XF86AudioLowerVolume" = {
          action.spawn = [
            pamixerExe
            "-d"
            "5"
          ];
          allow-when-locked = true;
        };
        "XF86AudioRaiseVolume" = {
          action.spawn = [
            pamixerExe
            "-i"
            "5"
          ];
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action.spawn = [
            pamixerExe
            "-t"
          ];
          allow-when-locked = true;
        };
      }
      # mouse bindings
      // {
        # having Mod + Scroll up / Down is impossible to control with trackball, so require Shift for workspaces
        "Mod+Shift+WheelScrollDown" = {
          action.focus-workspace-down = { };
          cooldown-ms = 150;
        };
        "Mod+Shift+WheelScrollUp" = {
          action.focus-workspace-up = { };
          cooldown-ms = 150;
        };

        "Mod+WheelScrollRight".action.focus-column-right-or-first = { };
        "Mod+WheelScrollLeft".action.focus-column-left-or-last = { };
      }
      # named workspace setup, dynamic workspaces are urgh
      // mergeAttrsList (
        flatten (
          (lib.custom.mapWorkspaces (
            { workspace, key, ... }:
            [
              {
                # Switch workspaces with mainMod + [0-9]
                "Mod+${key}".action.focus-workspace = "W${workspace}";
                # Move active window to a workspace with mainMod + SHIFT + [0-9]
                "Mod+Shift+${key}".action.move-column-to-workspace = "W${workspace}";
              }
            ]
          ))
            monitors
        )
      )
      // optionalAttrs config.custom.backlight.enable {
        "XF86MonBrightnessDown" = {
          action.spawn = [
            (getExe pkgs.brightnessctl)
            "set"
            "+5%"
          ];
          allow-when-locked = true;
        };
        "XF86MonBrightnessUp" = {
          action.spawn = [
            (getExe pkgs.brightnessctl)
            "set"
            "5%-"
          ];
          allow-when-locked = true;
        };
      };
  };
}
