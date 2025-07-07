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
    optionalAttrs
    ;
  inherit (config.custom) monitors;
  pamixerExe = getExe pkgs.pamixer;
  termExe = getExe config.custom.terminal.package;
  rofiExe = getExe config.programs.rofi.package;
in
{
  programs.niri.settings = {
    binds =
      {
        # Most actions that you can bind here can also be invoked programmatically with
        # `niri msg action do-something`.

        # show hotkey overlay
        # "Mod+Shift+Slash".action = show-hotkey-overlay;

        "Mod+Return".action.spawn = termExe;
        "Mod+Shift+Return".action.spawn = rofiExe;
        "Mod+BackSpace" = {
          action.close-window = { };
          repeat = false;
        };
        "Ctrl+Alt+Delete".action.spawn = getExe pkgs.custom.rofi-power-menu;

        # Open/close the Overview: a zoomed-out view of workspaces and windows.
        # You can also move the mouse into the top-left hot corner,
        # or do a four-finger swipe up on a touchpad.
        "Mod+O" = {
          action.toggle-overview = { };
          repeat = false;
        };

        "Mod+H".action.focus-column-left = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right = { };

        "Mod+Shift+H".action.move-column-left = { };
        "Mod+Shift+J".action.move-window-down = { };
        "Mod+Shift+K".action.move-window-up = { };
        "Mod+Shift+L".action.move-column-right = { };

        # Alternative commands that move across workspaces when reaching
        # the first or last window in a column.
        # Mod+J".action ="focus-window-or-workspace-down";
        # Mod+K".action ="focus-window-or-workspace-up";
        # Mod+Ctrl+J".action ="move-window-down-or-to-workspace-down";
        # Mod+Ctrl+K".action ="move-window-up-or-to-workspace-up";

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

        "Mod+U".action.focus-workspace-down = { };
        "Mod+I".action.focus-workspace-up = { };
        "Mod+Shift+U".action.move-column-to-workspace-down = { };
        "Mod+Shift+I".action.move-column-to-workspace-up = { };

        "Mod+WheelScrollDown" = {
          action.focus-workspace-down = { };
          cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          action.focus-workspace-up = { };
          cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollDown" = {
          action.move-column-to-workspace-down = { };
          cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollUp" = {
          action.move-column-to-workspace-up = { };
          cooldown-ms = 150;
        };

        "Mod+WheelScrollRight".action.focus-column-right = { };
        "Mod+WheelScrollLeft".action.focus-column-left = { };
        "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
        "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

        # Usually scrolling up and down with Shift in applications results in
        # horizontal scrolling; these binds replicate that.
        "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
        "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

        # Alternatively, there are commands to move just a single window:
        # Mod+Ctrl+1".action ="move-window-to-workspace 1";

        # Switches focus between the current and the previous workspace.
        # Mod+Tab".action ="focus-workspace-previous";

        # The following binds move the focused window in and out of a column.
        # If the window is alone, they will consume it into the nearby column to the side.
        # If the window is already in a column, they will expel it out.
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };

        # Consume one window from the right to the bottom of the focused column.
        "Mod+Comma".action.consume-window-into-column = { };
        # Expel the bottom window from the focused column to the right.
        "Mod+Period".action.expel-window-from-column = { };

        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.switch-preset-window-height = { };
        "Mod+Ctrl+R".action.reset-window-height = { };
        "Mod+F".action.maximize-column = { };
        "Mod+Shift+F".action.fullscreen-window = { };

        # Expand the focused column to space not taken up by other fully visible columns.
        # Makes the column"fill the rest of the space".
        "Mod+Ctrl+F".action.expand-column-to-available-width = { };

        "Mod+C".action.center-column = { };

        # Center all fully visible columns on screen.
        "Mod+Ctrl+C".action.center-visible-columns = { };

        # TODO: toggle floating
        # Move the focused window between the floating and the tiling layout.
        # "Mod+V".action = toggle-window-floating;
        # "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

        # Toggle tabbed column display mode.
        # Windows in this column will appear as vertical tabs,
        # rather than stacked on top of each other.
        # TODO: "Mod+W".action = toggle-column-tabbed-display;

        # Actions to switch layouts.
        # Note: if you uncomment these, make sure you do NOT have
        # a matching layout switch hotkey configured in xkb options above.
        # Having both at once on the same hotkey will break the switching,
        # since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
        # Mod+Space".action ="switch-layout"next"";
        # Mod+Shift+Space".action ="switch-layout"prev"";

        "Print".action.screenshot = { };
        # "Ctrl+Print".action = screenshot-screen; # not found?
        "Alt+Print".action.screenshot-window = { };

        "Mod+Apostrophe".action.spawn = "wallpaper rofi";
        "Mod+Shift+Apostrophe".action.spawn = "rofi-wallust-theme";
        "Alt+Apostrophe".action.spawn = "wallpaper history";

        # audio
        "XF86AudioLowerVolume" = {
          action.spawn = "${pamixerExe} -d 5";
          allow-when-locked = true;
        };
        "XF86AudioRaiseVolume" = {
          action.spawn = "${pamixerExe} -i 5";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action.spawn = "${pamixerExe} -t";
          allow-when-locked = true;
        };
      }
      # workspace setup
      // mergeAttrsList (
        flatten (
          (lib.custom.mapWorkspaces (
            { workspace, key, ... }:
            [
              {
                # Switch workspaces with mainMod + [0-9]
                "Mod+${key}".action.focus-workspace = workspace;
                # Move active window to a workspace with mainMod + SHIFT + [0-9]
                "Mod+Shift+${key}".action.move-column-to-workspace = workspace;
              }
            ]
          ))
            monitors
        )
      )
      // optionalAttrs config.custom.backlight.enable {
        "XF86MonBrightnessDown" = {
          action.spawn = "${getExe pkgs.brightnessctl} set +5%";
          allow-when-locked = true;
        };
        "XF86MonBrightnessUp" = {
          action.spawn = "${getExe pkgs.brightnessctl} set 5%-";
          allow-when-locked = true;
        };
      };
  };
}
