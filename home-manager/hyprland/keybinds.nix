{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.iynaix) displays;
  rofi = lib.getExe pkgs.rofi;
  pamixer = lib.getExe pkgs.pamixer;
in {
  wayland.windowManager.hyprland.settings = lib.mkIf config.wayland.windowManager.hyprland.enable {
    bind =
      [
        "$mod, Return, exec, $term"
        "$mod_SHIFT, Return, exec, ${rofi} -show drun"
        "$mod, BackSpace, killactive,"
        "$mod, e, exec, nemo ~/Downloads"
        "$mod_SHIFT, e, exec, $term yazi ~/Downloads"
        "$mod, w, exec, brave"
        "$mod_SHIFT, w, exec, brave --incognito"
        "$mod, v, exec, $term nvim"
        "$mod_SHIFT, v, exec, code"
        "$mod, period, exec, code ~/projects/dotfiles"

        # exit hyprland
        "$mod_ALT, F4, exit,"

        # without the rounding, the blur shows up around the corners
        ''CTRL_ALT, Delete, exec, rofi-power-menu''
        "$mod_CTRL, v, exec, cliphist list | ${rofi} -dmenu -theme $HOME/.cache/wallust/rofi-menu.rasi | cliphist decode | wl-copy"

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
        "$mod_SHIFT, f, fakefullscreen"

        # floating
        "$mod, g, togglefloating"

        # sticky
        "$mod, s, pin"

        # focus next / previous monitor
        "$mod, Left, focusmonitor, -1"
        "$mod, Right, focusmonitor, +1"

        # move to next / previous monitor
        "$mod_SHIFT, Left, movewindow, ${
          if builtins.length displays < 3
          then "mon:-1"
          else "mon:l"
        }"
        "$mod_SHIFT, Right, movewindow, ${
          if builtins.length displays < 3
          then "mon:+1"
          else "mon:r"
        }"
        "$mod_SHIFT, Up, movewindow, ${
          if builtins.length displays < 3
          then "mon:-1"
          else "mon:u"
        }"
        "$mod_SHIFT, Down, movewindow, ${
          if builtins.length displays < 3
          then "mon:+1"
          else "mon:d"
        }"

        "ALT, Tab, cyclenext"
        "ALT_SHIFT, Tab, cyclenext, prev"

        # switches to the next / previous window of the same class
        # hardcoded to SUPER so it doesn't clash on VM
        "SUPER, Tab, exec, hypr-same-class next"
        "SUPER_SHIFT, Tab, exec, hypr-same-class prev"

        # picture in picture mode
        "$mod, p, exec, hypr-pip"

        # add / remove master windows
        "$mod, m, layoutmsg, addmaster"
        "$mod_SHIFT, m, layoutmsg, removemaster"

        # rotate via switching master orientation
        "$mod, r, layoutmsg, orientationcycle left top"

        # Scroll through existing workspaces with mainMod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # turn monitors off
        "$mod_SHIFT_CTRL, l, dpms, off"

        # dunst controls
        "$mod, grave, exec, dunstctl history-pop"

        # switching wallpapers or themes
        "$mod, apostrophe, exec, imv-wallpaper"
        "$mod_SHIFT, apostrophe, exec, rofi-wallust-theme"

        # special keys
        # "XF86AudioPlay, mpvctl playpause"

        # audio
        ",XF86AudioLowerVolume, exec, ${pamixer} -d 5"
        ",XF86AudioRaiseVolume, exec, ${pamixer} -i 5"
        ",XF86AudioMute, exec, ${pamixer} -t"
      ]
      # workspace keybinds
      ++ lib.flatten (lib.concatMap ({
        name,
        workspaces,
        ...
      }:
        lib.forEach workspaces (ws: [
          # Switch workspaces with mainMod + [0-9]
          "$mod, ${toString (lib.mod ws 10)}, workspace, ${toString ws}"
          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mod_SHIFT, ${toString (lib.mod ws 10)}, movetoworkspace, ${toString ws}"
        ]))
      displays)
      ++ lib.optionals config.iynaix.wezterm.enable ["$mod, q, exec, wezterm start"]
      ++ lib.optionals config.iynaix.backlight.enable [
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
