{
  pkgs,
  host,
  system,
  user,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.iynaix.hyprland;
  displays = config.iynaix.displays;
  mod =
    if host == "vm"
    then "ALT"
    else "SUPER";
  # functions for creating hyprland config
  # https://github.com/hyprwm/Hyprland/pull/870#issuecomment-1319448768
  concatAttrs = arg: func: (
    assert builtins.isAttrs arg;
      builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList func arg)
  );
  mkHyprlandBinds = arg: (
    concatAttrs arg (
      name: value: (
        if builtins.isList value
        then
          (
            builtins.concatStringsSep "\n" (builtins.map (x: name + " = " + x) value)
          )
        else
          concatAttrs value (
            name2: value2: name + " = " + name2 + "," + (assert builtins.isString value2; value2)
          )
      )
    )
  );
in {
  imports = [
    ./screenshot.nix
    ./startup.nix
    # ./lock.nix
    # ./waybar.nix
    ./swww.nix
  ];

  config = lib.mkIf cfg.enable {
    home = {
      sessionVariables = {
        "XCURSOR_SIZE" = "24";
      };

      packages = with pkgs; [
        playerctl
        pciutils
        # clipboard history
        cliphist
        wl-clipboard
      ];
    };

    programs.zsh.shellAliases = {
      hypr-log = "cat /tmp/hypr/$(command ls -t /tmp/hypr/ | head -n 1)/hyprland.log";
    };

    xdg.configFile = {
      # various helper scripts for keybinds
      "hypr/same_class.py".source = ./same_class.py;
      "hypr/pip.py".source = ./pip.py;

      "hypr/hyprland.conf" = {
        text = lib.concatStringsSep "\n" [
          ''
            ${cfg.monitors}
            monitor = ,preferred,auto,auto

            input {
              kb_layout = us
              follow_mouse = 1

              touchpad {
                natural_scroll = false
                disable_while_typing = true
              }
            }

            general {
              gaps_in = ${
              toString (
                if host == "desktop"
                then 8
                else 4
              )
            }
              gaps_out = ${
              toString (
                if host == "desktop"
                then 8
                else 4
              )
            }
              border_size = 2
              layout = master
            }

            decoration {
              rounding = 4
              blur = ${lib.boolToString (host != "vm")}
              blur_size = 2
              blur_passes = 3
              blur_new_optimizations = true

              drop_shadow = ${lib.boolToString (host != "vm")}
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)

              # dim_inactive = true
              # dim_strength = 0.05

              # blurls = rofi
            }

            animations {
              enabled = ${lib.boolToString (host != "vm")}
              bezier = overshot, 0.05, 0.9, 0.1, 1.05
              bezier = smoothOut, 0.36, 0, 0.66, -0.56
              bezier = smoothIn, 0.25, 1, 0.5, 1

              animation = windows, 1, 5, overshot, slide
              animation = windowsOut, 1, 4, smoothOut, slide
              animation = windowsMove, 1, 4, smoothIn, slide
              animation = border, 1, 5, default
              animation = fade, 1, 5, smoothIn
              animation = fadeDim, 1, 5, smoothIn
              animation = workspaces, 1, 6, default
            }

            dwindle {
              pseudotile = true
              preserve_split = true
            }

            master {
              new_is_master = false
              mfact = 0.5
              orientation = left
            }

            binds {
              workspace_back_and_forth = true
            }

            # xwayland {
            #   force_zero_scaling = true
            # }

            misc {
              disable_hyprland_logo = true
              disable_splash_rendering = true
              mouse_move_enables_dpms = true
              animate_manual_resizes = true
              # animate_mouse_windowdragging = true
              # key_press_enables_dpms = true
              enable_swallow = true
              swallow_regex = [Kk]itty|[Ww]ezterm
            }
          ''
          cfg.extraVariables
          (mkHyprlandBinds {
            bind = {
              "${mod}, Return" = "exec, ${lib.getExe config.iynaix.terminal.package}";
              "${mod}_SHIFT, Return" = "exec, rofi -show drun";
              "${mod}, BackSpace" = "killactive,";
              "${mod}, e" = "exec, nemo ~/Downloads";
              "${mod}_SHIFT, e" = "exec, ${config.iynaix.terminal.exec} ranger ~/Downloads";
              "${mod}, w" = "exec, brave";
              "${mod}_SHIFT, w" = "exec, brave --incognito";
              "${mod}, v" = "exec, ${config.iynaix.terminal.exec} nvim";
              "${mod}_SHIFT, v" = "exec, code";
              "${mod}, period" = "exec, code ~/projects/dotfiles";

              # exit hyprland
              "${mod}_SHIFT, c" = "exit,";

              "CTRL_ALT, Delete" = ''exec, rofi -show power-menu -font "${config.iynaix.font.monospace} 14" -modi power-menu:rofi-power-menu'';
              "${mod}_CTRL, v" = "exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy";

              # reset monitors
              "CTRL_SHIFT, Escape" = "exec, hypr-monitors";

              # bind = ${mod}, P, pseudo, # dwindle
              # bind = ${mod}, J, togglesplit, # dwindle

              "${mod}, h" = "movefocus, l";
              "${mod}, l" = "movefocus, r";
              "${mod}, j" = "movefocus, u";
              "${mod}, k" = "movefocus, d";

              "${mod}_SHIFT, h" = "movewindow, l";
              "${mod}_SHIFT, l" = "movewindow, r";
              "${mod}_SHIFT, k" = "movewindow, u";
              "${mod}_SHIFT, j" = "movewindow, d";

              # Switch workspaces with mainMod + [0-9]
              "${mod}, 1" = "workspace, 1";
              "${mod}, 2" = "workspace, 2";
              "${mod}, 3" = "workspace, 3";
              "${mod}, 4" = "workspace, 4";
              "${mod}, 5" = "workspace, 5";
              "${mod}, 6" = "workspace, 6";
              "${mod}, 7" = "workspace, 7";
              "${mod}, 8" = "workspace, 8";
              "${mod}, 9" = "workspace, 9";
              "${mod}, 0" = "workspace, 10";

              # Move active window to a workspace with mainMod + SHIFT + [0-9]
              "${mod}_SHIFT, 1" = "movetoworkspace, 1";
              "${mod}_SHIFT, 2" = "movetoworkspace, 2";
              "${mod}_SHIFT, 3" = "movetoworkspace, 3";
              "${mod}_SHIFT, 4" = "movetoworkspace, 4";
              "${mod}_SHIFT, 5" = "movetoworkspace, 5";
              "${mod}_SHIFT, 6" = "movetoworkspace, 6";
              "${mod}_SHIFT, 7" = "movetoworkspace, 7";
              "${mod}_SHIFT, 8" = "movetoworkspace, 8";
              "${mod}_SHIFT, 9" = "movetoworkspace, 9";
              "${mod}_SHIFT, 0" = "movetoworkspace, 10";

              "${mod}, b" = "layoutmsg, swapwithmaster";

              # set master to vertical on every navigation to the workspace
              # "${mod}, 6" = "layoutmsg, orientationtop";
              # "${mod}, 7" = "layoutmsg, orientationtop";
              # "${mod}, 8" = "layoutmsg, orientationtop";

              # "${mod}_SHIFT, 6" = "layoutmsg, orientationtop";
              # "${mod}_SHIFT, 7" = "layoutmsg, orientationtop";
              # "${mod}_SHIFT, 8" = "layoutmsg, orientationtop";

              # focus the previous / next desktop in the current monitor (DE style)
              "CTRL_ALT, Left" = "workspace, m-1";
              "CTRL_ALT, Right" = "workspace, m+1";

              # monocle mode
              "${mod}, z" = "fullscreen, 1";

              # fullscreen
              "${mod}, f" = "fullscreen, 0";
              "${mod}_SHIFT, f" = "fakefullscreen";

              # floating
              "${mod}, g" = "togglefloating";

              # sticky
              "${mod}, s" = "pin";

              # focus next / previous monitor
              "${mod}, Left" = "focusmonitor, -1";
              "${mod}, Right" = "focusmonitor, +1";

              # move to next / previous monitor
              "${mod}_SHIFT, Left" = "movewindow, mon:-1";
              "${mod}_SHIFT, Right" = "movewindow, mon:+1";

              "ALT, Tab" = "cyclenext";
              "ALT_SHIFT, Tab" = "cyclenext, prev";

              # switches to the next / previous window of the same class
              # hardcoded to SUPER so it doesn't clash on VM
              "SUPER, Tab" = "exec, ${pkgs.python3}/bin/python ~/.config/hypr/same_class.py next";
              "SUPER_SHIFT, Tab" = "exec, ${pkgs.python3}/bin/python ~/.config/hypr/same_class.py prev";

              # picture in picture mode
              "${mod}, p" = "exec, ${pkgs.python3}/bin/python ~/.config/hypr/pip.py";

              # add / remove master windows
              "${mod}, m" = "layoutmsg, addmaster";
              "${mod}_SHIFT, m" = "layoutmsg, removemaster";

              # rotate via switching master orientation
              "${mod}, r" = "layoutmsg, orientationnext";
              "${mod}_SHIFT, r" = "layoutmsg, orientationprev";

              # Scroll through existing workspaces with mainMod + scroll
              "${mod}, mouse_down" = "workspace, e+1";
              "${mod}, mouse_up" = "workspace, e-1";

              # lock monitors
              "${mod}_SHIFT_CTRL, l" = "dpms, off";

              # dunst controls
              "${mod}, grave" = "exec, dunstctl history-pop";

              "${mod}, q" = "exec, wezterm start";

              # switching wallpapers or themes
              "${mod}, apostrophe" = "exec, hypr-wallpaper --rofi wallpaper";
              "${mod}_SHIFT, apostrophe" = "exec, hypr-wallpaper --rofi theme";

              # TODO:
              # special keys
              # "XF86AudioPlay" = "mpvctl playpause";
            };

            # Move/resize windows with mainMod + LMB/RMB and dragging
            bindm = {
              "${mod}, mouse:272" = "movewindow";
              "${mod}, mouse:273" = "resizewindow";
            };

            # bind workspaces to monitors
            workspace = {
              "1" = "monitor:${displays.monitor1}";
              "2" = "monitor:${displays.monitor1}";
              "3" = "monitor:${displays.monitor1}";
              "4" = "monitor:${displays.monitor1}";
              "5" = "monitor:${displays.monitor1}";
              "6" = "monitor:${displays.monitor2}";
              "7" = "monitor:${displays.monitor2}";
              "8" = "monitor:${displays.monitor2}";
              "9" = "monitor:${displays.monitor3}";
              "10" = "monitor:${displays.monitor3}";
            };

            windowrulev2 = [
              # "dimaround,floating:1"
            ];

            windowrule = [
              # do not idle while watching videos
              "idleinhibit fullscreen,Brave-browser"
              "idleinhibit fullscreen,firefox-aurora"
              "idleinhibit focus,YouTube"
              "idleinhibit focus,mpv"
            ];

            exec-once = [
              # clipboard manager
              "wl-paste - -watch cliphist store"
            ];
          })
          (mkHyprlandBinds cfg.extraBinds)
          # "source=~/.config/hypr/hyprland-test.conf"
        ];
      };
    };
  };
}
