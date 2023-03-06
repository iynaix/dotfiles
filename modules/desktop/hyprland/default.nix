{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  mod = if host == "vm" then "ALT" else "SUPER";
  keybindsToStr = keybinds: lib.concatStringsSep "\n" (lib.mapAttrsToList
    (keys: action: "bind = ${keys}, ${action}")
    keybinds);
in
{
  imports = [ ./nvidia.nix ];

  options.iynaix.hyprland = {
    # mutually exclusive with bspwm
    enable = lib.mkEnableOption "Hyprland" // {
      default = (!config.iynaix.bspwm && !config.iynaix.gnome3);
    };
    keybinds = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = ''
        Keybinds for Hyprland, see
        https://wiki.hyprland.org/Configuring/Binds/
      '';
      example = ''{
        "SUPER, Return" = "exec, alacritty";
      }'';
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

    home-manager. users.${ user} = {
      programs. rofi = {
        package = pkgs.rofi-wayland;
        extraConfig = {
          modi = "run,drun";
        };
      };

      home.sessionVariables = {
        "XCURSOR_SIZE" = "24";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;
        extraConfig = (lib.concatStringsSep "\n" [
          cfg.monitors
          # See https://wiki.hyprland.org/Configuring/Keywords/

          # Execute your favorite apps at launch
          # exec-once = waybar & hyprpaper & firefox

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
              gaps_in = 5
              gaps_out = 20
              border_size = 2
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              layout = master
            }
          ''

          # See https://wiki.hyprland.org/Configuring/Variables/
          ''
            decoration {
              rounding = 10
              blur = true
              blur_size = 3
              blur_passes = 1
              blur_new_optimizations = true

              drop_shadow = true
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)
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
              new_is_master = true
            }
          ''

          # See https://wiki.hyprland.org/Configuring/Variables/
          ''
            gestures {
              workspace_swipe = false
            }
          ''

          # Example per-device config
          # See https://wiki.hyprland.org/Configuring/Keywords/#executing
          ''
            device:epic mouse V1 {
              sensitivity = -0.5
            }
          ''

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
          # See https://wiki.hyprland.org/Configuring/Window-Rules/

          # see https://wiki.hyprland.org/Configuring/Binds/
          (keybindsToStr ({
            "${mod}, Return" = "exec, alacritty";
            "${mod}_SHIFT, Return" = "exec, rofi -show drun";
            "${mod}, BackSpace" = "killactive,";
            "${mod}, E" = "exec, nemo ~/Downloads";
            "${mod}_SHIFT, E" = "exec, alacritty -e ranger ~/Downloads";
            "${mod}, W" = "exec, brave";
            "${mod}_SHIFT, W" = "exec, brave --incognito";
            "${mod}, V" = "exec, alacritty -e nvim";
            "${mod}_SHIFT, V" = "exec, code";

            "CTRL_ALT, Delete" = ''exec, rofi -show power-menu -font "${config.iynaix.font.regular} 14" -modi power-menu:rofi-power-menu'';
            "${mod}_CTRL, V" = "exec, clipmenu";

            # bind = ${mod}, P, pseudo, # dwindle
            # bind = ${mod}, J, togglesplit, # dwindle

            # Move focus with mainMod + arrow keys
            "${mod}, left" = "movefocus, l";
            "${mod}, right" = "movefocus, r";
            "${mod}, up" = "movefocus, u";
            "${mod}, down" = "movefocus, d";

            "${mod}, h" = "movefocus, l";
            "${mod}, l" = "movefocus, r";
            "${mod}, j" = "movefocus, u";
            "${mod}, k" = "movefocus, d";

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
            "${mod} SHIFT, 1" = "movetoworkspace, 1";
            "${mod} SHIFT, 2" = "movetoworkspace, 2";
            "${mod} SHIFT, 3" = "movetoworkspace, 3";
            "${mod} SHIFT, 4" = "movetoworkspace, 4";
            "${mod} SHIFT, 5" = "movetoworkspace, 5";
            "${mod} SHIFT, 6" = "movetoworkspace, 6";
            "${mod} SHIFT, 7" = "movetoworkspace, 7";
            "${mod} SHIFT, 8" = "movetoworkspace, 8";
            "${mod} SHIFT, 9" = "movetoworkspace, 9";
            "${mod} SHIFT, 0" = "movetoworkspace, 10";

            # Scroll through existing workspaces with mainMod + scroll
            "${mod}, mouse_down" = "workspace, e+1";
            "${mod}, mouse_up" = "workspace, e-1";
          }))

          # Move/resize windows with mainMod + LMB/RMB and dragging
          "bindm = ${mod}, mouse:272, movewindow"
          "bindm = ${mod}, mouse:273, resizewindow"

          # additional keybind
          (keybindsToStr cfg.keybinds)

          "source=~/.config/hyprland-extra.conf"
        ]);
      };
    };
  };
}
