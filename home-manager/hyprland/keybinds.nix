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
lib.mkIf config.custom.hyprland.enable {
  wayland.windowManager.hyprland.settings = {
    bind =
      let
        workspace_keybinds = lib.flatten (
          (pkgs.custom.lib.mapWorkspaces (
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
        "$mod, Return, exec, $term"
        "$mod_SHIFT, Return, exec, rofi -show drun"
        "$mod, BackSpace, killactive,"
        "$mod, e, exec, nemo ${config.xdg.userDirs.download}"
        "$mod_SHIFT, e, exec, $term yazi ${config.xdg.userDirs.download}"
        "$mod, w, exec, brave"
        "$mod_SHIFT, w, exec, brave --incognito"
        "$mod, v, exec, $term nvim"
        "$mod_SHIFT, v, exec, code"
        "$mod, period, exec, code ${config.home.homeDirectory}/projects/dotfiles"
        "$mod_SHIFT, period, exec, code ${config.home.homeDirectory}/projects/nixpkgs"

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

        # resizing windows
        "$mod_CTRL, h, resizeactive, -20 0"
        "$mod_CTRL, l, resizeactive, 20 0"
        "$mod_CTRL, k, resizeactive, 0 -20"
        "$mod_CTRL, j, resizeactive, 0 20"

        "$mod, b, layoutmsg, swapwithmaster"

        # focus the previous / next desktop in the current monitor (DE style)
        "CTRL_ALT, Left, workspace, m-1"
        "CTRL_ALT, Right, workspace, m+1"

        # monocle mode
        "$mod, z, fullscreen, 1"

        # fullscreen
        "$mod, f, fullscreen, 0"
        "$mod_SHIFT, f, fakefullscreen"

        # floating
        "$mod, g, togglefloating"

        # sticky
        "$mod, s, pin"

        # focus next / previous monitor
        "$mod, Tab, focusmonitor, +1"
        # move to next / previous monitor
        "$mod_SHIFT, Tab, movewindow, mon:+1"

        "ALT, Tab, cyclenext"
        "ALT_SHIFT, Tab, cyclenext, prev"

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
        "$mod, grave, exec, dunstctl history-pop"

        # switching wallpapers or themes
        "$mod, apostrophe, exec, wallpapers-select"
        "$mod_SHIFT, apostrophe, exec, rofi-wallust-theme"

        # special keys
        # "XF86AudioPlay, mpvctl playpause"

        # audio
        ",XF86AudioLowerVolume, exec, ${pamixer} -d 5"
        ",XF86AudioRaiseVolume, exec, ${pamixer} -i 5"
        ",XF86AudioMute, exec, ${pamixer} -t"
      ]
      ++ workspace_keybinds
      # turn monitors off
      ++ lib.optionals (host == "desktop") [ "$mod_SHIFT_CTRL, x, dpms, off" ]
      ++ lib.optionals config.custom.backlight.enable [
        ",XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} set 5%-"
        ",XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} set +5%"
      ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
