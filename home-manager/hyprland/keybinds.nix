{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.custom) monitors;
  pamixer = lib.getExe pkgs.pamixer;
  qtile_like = config.custom.hyprland.qtile;
in
{
  options.custom = with lib; {
    hyprland = {
      qtile = mkEnableOption "qtile like behavior for workspaces";
    };
  };

  config = lib.mkIf config.custom.hyprland.enable {
    custom.shell.packages = {
      focusorrun = {
        runtimeInputs = with pkgs; [
          hyprland
          jq
        ];
        # $1 is string to search for in window title
        # $2 is the command to run if the window isn't found
        text = ''
          address=$(hyprctl clients -j | jq -r ".[] | select(.title | contains(\"$1\")) | \"address:\(.address)\"")

          if [ -z "$address" ]; then
            eval "$2"
          else
            hyprctl dispatch focuswindow "$address"
          fi
        '';
      };
    };

    wayland.windowManager.hyprland.settings =
      let
        workspace_keybinds = lib.flatten (
          (lib.custom.mapWorkspaces (
            { workspace, key, ... }:
            if qtile_like then
              [
                # Switch workspaces with mainMod + [0-9]
                "$mod, ${key}, focusworkspaceoncurrentmonitor, ${workspace}"
                # Move active window to a workspace with mainMod + SHIFT + [0-9]
                "$mod_SHIFT, ${key}, movetoworkspace, ${workspace}"
                "$mod_SHIFT, ${key}, focusworkspaceoncurrentmonitor, ${workspace}"
              ]
            else
              [
                # Switch workspaces with mainMod + [0-9]
                "$mod, ${key}, workspace, ${workspace}"
                # Move active window to a workspace with mainMod + SHIFT + [0-9]
                "$mod_SHIFT, ${key}, movetoworkspace, ${workspace}"
              ]
          ))
            monitors
        );
      in
      {
        bind =
          [
            "$mod, Return, exec, $term"
            "$mod_SHIFT, Return, exec, rofi -show drun"
            "$mod, BackSpace, killactive,"
            "$mod, e, exec, nemo ${config.xdg.userDirs.download}"
            "$mod_SHIFT, e, exec, $term yazi ${config.xdg.userDirs.download}"
            "$mod, w, exec, brave"
            "$mod_SHIFT, w, exec, rofi-epub-menu"
            "$mod_CTRL, w, exec, rofi-pdf-menu"
            "$mod, t, exec, jerry"
            "$mod, v, exec, $term hx"
            "$mod_SHIFT, v, exec, ${lib.getExe pkgs.custom.shell.rofi-edit-proj}"
            ''$mod, period, exec, focusorrun "dotfiles - VSCodium" "codium ${config.home.homeDirectory}/projects/dotfiles"''
            ''$mod_SHIFT, period, exec, focusorrun "nixpkgs - VSCodium" "codium ${config.home.homeDirectory}/projects/nixpkgs"''

            # exit hyprland
            "$mod_ALT, F4, exit,"

            # without the rounding, the blur shows up around the corners
            "CTRL_ALT, Delete, exec, rofi-power-menu"
            "$mod_CTRL, v, exec, cliphist list | rofi -dmenu -theme ${config.xdg.cacheHome}/wallust/rofi-menu.rasi | cliphist decode | wl-copy"

            # reset monitors
            "CTRL_SHIFT, Escape, exec, hypr-monitors"

            # bind = $mod, P, pseudo, # dwindle
            # bind = $mod, J, togglesplit, # dwindle

            "$mod, h, movefocus, l"
            "$mod, l, movefocus, r"
            "$mod, j, movefocus, u"
            "$mod, k, movefocus, d"

            "$mod_SHIFT, h, movewindow, l"
            "$mod_SHIFT, l, movewindow, r"
            "$mod_SHIFT, k, movewindow, u"
            "$mod_SHIFT, j, movewindow, d"

            "$mod, b, layoutmsg, swapwithmaster"

            # focus the previous / next desktop in the current monitor (DE style)
            "CTRL_ALT, Left, workspace, m-1"
            "CTRL_ALT, Right, workspace, m+1"

            # monocle mode
            "$mod, z, fullscreen, 1"

            # fullscreen
            "$mod, f, fullscreen, 0"
            # "$mod_SHIFT, f, fakefullscreen"
            "$mod_SHIFT, f, fullscreenstate, -1 2"

            # floating
            "$mod, g, togglefloating"

            # sticky
            "$mod, s, pin"

            # focus next / previous monitor
            "$mod, Tab, focusmonitor, +1"
            # move to next / previous monitor
            "$mod_SHIFT, Tab, movewindow, mon:+1"

            # classic alt tab in a workspace
            "ALT, Tab, cyclenext"
            "ALT_SHIFT, Tab, cyclenext, prev"

            # toggle between prev and current windows
            "$mod, grave, focuscurrentorlast"

            # switches to the next / previous window of the same class
            # hardcoded to SUPER so it doesn't clash on VM
            "CTRL_ALT_, Tab, exec, hypr-same-class next"
            "CTRL_ALT_SHIFT, Tab, exec, hypr-same-class prev"

            # picture in picture mode
            "$mod, p, exec, hypr-pip"

            # add / remove master windows
            "$mod, m, layoutmsg, addmaster"
            "$mod_SHIFT, m, layoutmsg, removemaster"

            # rotate via switching master orientation
            # "$mod, r, layoutmsg, orientationcycle left top"

            # Scroll through existing workspaces with mainMod + scroll
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up, workspace, e-1"

            # dunst controls
            "$mod, n, exec, dunstctl history-pop"

            # switching wallpapers or themes
            "$mod, apostrophe, exec, wallpaper rofi"
            "$mod_SHIFT, apostrophe, exec, rofi-wallust-theme"
            "ALT, apostrophe, exec, wallpaper history"

            # special keys
            # "XF86AudioPlay, mpvctl playpause"

            # audio
            ",XF86AudioMute, exec, ${pamixer} -t"
          ]
          ++ workspace_keybinds
          # turn monitors off
          ++ lib.optionals (host == "desktop") [ "$mod_SHIFT_CTRL, x, dpms, off" ]
          ++ lib.optionals config.custom.backlight.enable [
            ",XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} set 5%-"
            ",XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} set +5%"
          ];
        bindel = [
          # audio
          ",XF86AudioLowerVolume, exec, ${pamixer} -d 5"
          ",XF86AudioRaiseVolume, exec, ${pamixer} -i 5"

          # resizing windows
          "$mod_CTRL, h, resizeactive, -20 0"
          "$mod_CTRL, l, resizeactive, 20 0"
          "$mod_CTRL, k, resizeactive, 0 -20"
          "$mod_CTRL, j, resizeactive, 0 20"
        ];

        # Move/resize windows with mainMod + LMB/RMB and dragging
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod_SHIFT, mouse:272, resizewindow"
        ];
      };
  };
}
