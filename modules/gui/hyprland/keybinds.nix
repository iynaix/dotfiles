{
  config,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    flatten
    mkEnableOption
    mkIf
    optionals
    ;
  inherit (config.custom.hardware) monitors;
  termExec = cmd: "ghostty -e ${cmd}";
  qtile_like = config.custom.programs.hyprland.qtile;
in
{
  options.custom = {
    programs.hyprland = {
      qtile = mkEnableOption "qtile like behavior for workspaces";
    };
  };

  config = mkIf (config.custom.wm == "hyprland") {
    custom.shell.packages = {
      focus-or-run = {
        runtimeInputs = with pkgs; [
          hyprland
          jq
        ];
        # $1 is string to search for in window title
        # $2 is the command to run if the window isn't found
        text = # sh
          ''
            address=$(hyprctl clients -j | jq -r ".[] | select(.title | contains(\"$1\")) | .address")

            if [ -z "$address" ]; then
              eval "$2"
            else
              hyprctl dispatch focuswindow "address:$address"
            fi
          '';
      };
    };

    custom.programs.hyprland.settings = {
      bind =
        let
          workspace_keybinds = flatten (
            (libCustom.mapWorkspaces (
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
        [
          "$mod, Return, exec, ghostty"
          "$mod_SHIFT, Return, exec, rofi -show drun"
          "$mod, BackSpace, killactive,"
          "$mod, e, exec, nemo ${config.hj.directory}/Downloads"
          "$mod_SHIFT, e, exec, ${termExec "yazi ${config.hj.directory}/Downloads}"}"
          "$mod, w, exec, helium"
          "$mod_SHIFT, w, exec, helium --incognito"
          "$mod, v, exec, ${termExec "nvim"}"
          "$mod_SHIFT, v, exec, rofi-edit-proj"
          ''$mod, period, exec, focus-or-run "dotfiles - VSCodium" "codium ${config.hj.directory}/projects/dotfiles"''
          ''$mod_SHIFT, period, exec, focus-or-run "nixpkgs - VSCodium" "codium ${config.hj.directory}/projects/nixpkgs"''

          # exit hyprland
          "ALT, F4, exit,"
          # without the rounding, the blur shows up around the corners
          "CTRL_ALT, Delete, exec, rofi-power-menu"

          # clipboard history
          "$mod_CTRL, v, exec, rofi-clipboard-history"

          # reset monitors
          "CTRL_SHIFT, Escape, exec, hypr-monitors"

          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, j, movefocus, u"
          "$mod, k, movefocus, d"

          "$mod_SHIFT, h, movewindow, l"
          "$mod_SHIFT, l, movewindow, r"
          "$mod_SHIFT, k, movewindow, u"
          "$mod_SHIFT, j, movewindow, d"

          "$mod, b, layoutmsg, swapwithmaster"

          # focus the previous / next workspace in the current monitor (DE style)
          "$mod, Left, workspace, m-1"
          "$mod, Right, workspace, m+1"

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
          "CTRL_ALT_, Tab, exec, wm-same-class next"
          "CTRL_ALT_SHIFT, Tab, exec, wm-same-class prev"

          # picture in picture mode
          "$mod, p, exec, wm-pip"

          # add / remove master windows
          "$mod, m, layoutmsg, addmaster"
          "$mod_SHIFT, m, layoutmsg, removemaster"

          # rotate via switching master orientation
          # "$mod, r, layoutmsg, orientationcycle left top"

          # Scroll through existing workspaces with mainMod + scroll
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # switching wallpapers or themes
          "$mod, apostrophe, exec, wallpaper rofi"
          "$mod_SHIFT, apostrophe, exec, rofi-wallust-theme"
          "ALT, apostrophe, exec, wallpaper history"

          # special keys
          # "XF86AudioPlay, mpvctl playpause"

          # audio
          ",XF86AudioLowerVolume, exec, pamixer -d 5"
          ",XF86AudioRaiseVolume, exec, pamixer -i 5"
          ",XF86AudioMute, exec, pamixer -t"
        ]
        # invert windows
        ++ optionals config.custom.programs.hypr-darkwindow.enable [ "$mod_shift, i ,invertactivewindow" ]
        ++ workspace_keybinds
        ++ optionals config.custom.hardware.backlight.enable [
          ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ];

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
