{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  displays = config.iynaix.displays;
  mod = if host == "vm" then "ALT" else "SUPER";
  keybindsToStr = keybinds: lib.concatStringsSep "\n" (lib.mapAttrsToList
    (keys: action: "bind = ${keys}, ${action}")
    keybinds);
in
{
  imports = [
    ./nvidia.nix
    ./startup.nix
    ./waybar.nix
    ./wallpaper.nix
  ];

  options.iynaix.hyprland = {
    # mutually exclusive with bspwm
    enable = lib.mkEnableOption "Hyprland" // {
      default = (!config.iynaix.bspwm && !config.iynaix.gnome3);
    };
    keybinds = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = ''
        Keybinds for Hyprland, see
        https://wiki.hyprland.org/Configuring/Binds/
      '';
      example = ''{
        "SUPER, Return" = "exec, alacritty";
      }'';
      default = {
        "${mod}, Return" = "exec, alacritty";
        "${mod}_SHIFT, Return" = "exec, rofi -show drun";
        "${mod}, BackSpace" = "killactive,";
        "${mod}, e" = "exec, nemo ~/Downloads";
        "${mod}_SHIFT, e" = "exec, alacritty -e ranger ~/Downloads";
        "${mod}, w" = "exec, brave";
        "${mod}_SHIFT, w" = "exec, brave --incognito";
        "${mod}, v" = "exec, alacritty -e nvim";
        "${mod}_SHIFT, v" = "exec, code";

        "CTRL_ALT, Delete" = ''exec, rofi -show power-menu -font "${config.iynaix.font.regular} 14" -modi power-menu:rofi-power-menu'';
        "${mod}_CTRL, v" = "exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy";

        # reload
        "CTRL_SHIFT, Escape" = "forcerendererreload";

        # bind = ${mod}, P, pseudo, # dwindle
        # bind = ${mod}, J, togglesplit, # dwindle

        # Move focus with mainMod + arrow keys
        # "${mod}, left" = "movefocus, l";
        # "${mod}, right" = "movefocus, r";
        # "${mod}, up" = "movefocus, u";
        # "${mod}, down" = "movefocus, d";

        "${mod}, h" = "movefocus, l";
        "${mod}, l" = "movefocus, r";
        "${mod}, j" = "movefocus, u";
        "${mod}, k" = "movefocus, d";

        "${mod}_SHIFT, h" = "movewindow, l";
        "${mod}_SHIFT, l" = "movewindow, r";
        "${mod}_SHIFT, j" = "movewindow, u";
        "${mod}_SHIFT, k" = "movewindow, d";

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

        # toggle between previous and current window
        "${mod}, grave" = "focuscurrentorlast";

        # add / remove master windows
        "${mod}, m" = "layoutmsg, addmaster";
        "${mod}_SHIFT, m" = "layoutmsg, removemaster";

        # rotate via switching master orientation
        "${mod}, r" = "layoutmsg, orientationnext";

        # Scroll through existing workspaces with mainMod + scroll
        "${mod}, mouse_down" = "workspace, e+1";
        "${mod}, mouse_up" = "workspace, e-1";

        # TODO:
        # screenshots
        # "${mod} + shift + backslash" = "rofi-screenshot";

        # special keys
        # "XF86AudioPlay" = "mpvctl playpause";

        # equalize size of windows at parent / root level
        # "${mod} + {_,ctrl + }equal" = "bspc node {@parent,@/} --balance";

        # focus the next/previous node of the same class
        # "${mod} + {_,shift + }Tab" = "bspc node -f {next,prev}.same_class";
      };
    };
    monitors = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Config for monitors, see
        https://wiki.hyprland.org/Configuring/Monitors/
      '';
    };
    settings = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "Settings for Hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;

    services.greetd = {
      enable = true;
      settings = {
        default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd Hyprland";

        initial_session = {
          command = "Hyprland";
          inherit user;
        };
      };
    };

    # iynaix.hyprland.keybinds = // lib.optionalAttrs (host == "desktop") {
    #     # set master to vertical on every navigation to the workspace
    #     "${mod}, 6" = "layoutmsg, orientationtop";
    #     "${mod}, 7" = "layoutmsg, orientationtop";
    #     "${mod}, 8" = "layoutmsg, orientationtop";

    #     "${mod}_SHIFT, 6" = "layoutmsg, orientationtop";
    #     "${mod}_SHIFT, 7" = "layoutmsg, orientationtop";
    #     "${mod}_SHIFT, 8" = "layoutmsg, orientationtop";
    #   };

    home-manager.users.${user} = {
      programs.rofi = {
        package = pkgs.rofi-wayland;
        extraConfig = {
          modi = "run,drun";
        };
      };

      home = {
        sessionVariables = {
          "XCURSOR_SIZE" = "24";
        };

        packages = with pkgs; [
          # clipboard history
          cliphist
          wl-clipboard
        ];
      };

      wayland.windowManager.hyprland =
        let
          xrdb = lib.mapAttrs (name: value: (lib.substring 1 50 value)) config.iynaix.xrdb;
        in
        {
          enable = true;
          systemdIntegration = true;
          extraConfig = (lib.concatStringsSep "\n" [
            # handles displays that are plugged in
            "monitor=,preferred,auto,auto"
            cfg.monitors

            # bind workspaces to monitors
            "wsbind=1,${displays.monitor1}"
            "wsbind=2,${displays.monitor1}"
            "wsbind=3,${displays.monitor1}"
            "wsbind=4,${displays.monitor1}"
            "wsbind=5,${displays.monitor1}"
            "wsbind=6,${displays.monitor2}"
            "wsbind=7,${displays.monitor2}"
            "wsbind=8,${displays.monitor2}"
            "wsbind=9,${displays.monitor3}"
            "wsbind=10,${displays.monitor3}"
            # See https://wiki.hyprland.org/Configuring/Keywords/

            # Source a file (multi-file configs)
            # source = ~/.config/hypr/myColors.conf
            ''
              input {
                kb_layout = us
                kb_variant =
                kb_model =
                kb_options =
                kb_rules =

                follow_mouse = 1

                touchpad {
                  natural_scroll = false
                }

                sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
              }
            ''

            # See https://wiki.hyprland.org/Configuring/Variables/
            ''
              general {
                gaps_in = ${toString (if host == "desktop" then 8 else 4)}
                gaps_out = ${toString (if host == "desktop" then 8 else 4)}
                border_size = 2
                # col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
                # col.inactive_border = rgba(595959aa)
                # col.active_border = rgba(${xrdb.color4}ee) rgba(${xrdb.color2}55)
                col.active_border = rgb(${xrdb.color4})
                col.inactive_border = rgb(${xrdb.color0})

                layout = master
              }
            ''

            # See https://wiki.hyprland.org/Configuring/Variables/
            ''
              decoration {
                rounding = 8
                blur = true
                blur_size = 3
                blur_passes = 1
                blur_new_optimizations = true

                drop_shadow = true
                shadow_range = 4
                shadow_render_power = 3
                col.shadow = rgba(1a1a1aee)

                # dim_inactive = true
                # dim_strength = 0.05
              }
            ''

            # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/

            ''
              animations {
                enabled = true

                bezier = myBezier, 0.05, 0.9, 0.1, 1.05

                animation = windows, 1, 7, myBezier
                animation = windowsOut, 1, 7, default, popin 80%
                animation = border, 1, 10, default
                animation = borderangle, 1, 8, default
                animation = fade, 1, 7, default
                animation = workspaces, 1, 6, default
              }
            ''

            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/
            ''
              dwindle {
                pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
                preserve_split = true # you probably want this
              }
            ''

            # See https://wiki.hyprland.org/Configuring/Master-Layout/
            ''
              master {
                new_is_master = false
              }
            ''

            ''
              binds {
                workspace_back_and_forth = true
              }
            ''

            # Example windowrule v1
            # windowrule = float, ^(kitty)$
            # Example windowrule v2
            # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
            # See https://wiki.hyprland.org/Configuring/Window-Rules/

            # see https://wiki.hyprland.org/Configuring/Binds/
            (keybindsToStr cfg.keybinds)

            # Move/resize windows with mainMod + LMB/RMB and dragging
            "bindm = ${mod}, mouse:272, movewindow"
            "bindm = ${mod}, mouse:273, resizewindow"

            "exec = hyprpaper" # reload wallpaper every time
            "exec-once = wl-paste --watch cliphist store" # clipboard manager

            (lib.concatStringsSep "\n" cfg.startupPrograms)

            "source=~/.config/hyprland-extra.conf"
          ]);
        };
    };
  };
}
