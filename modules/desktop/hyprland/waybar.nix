{
  pkgs,
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.waybar;
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    killall -q .waybar-wrapped
    waybar --config $HOME/.cache/wallust/waybar-config \
        --style $HOME/.cache/wallust/waybar-style.css \
        > /dev/null 2>&1 &
  '';
in {
  options.iynaix.waybar = {
    enable = lib.mkEnableOption "waybar" // {default = true;};
    settings-template = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Additional waybar settings in wallust template format (original format is json)";
    };
    style-template = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Additional waybar css styles in wallust template format (original format is css)";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      home.packages = [launch-waybar];

      programs.waybar = {
        enable = true;
        # patch waybar for hyprland workspaces
        package = pkgs.hyprland.waybar-hyprland;
      };
    };

    iynaix.wallust.entries = {
      waybar-config = {
        enable = config.iynaix.wallust.waybar;
        text = lib.mkDefault ''
          {
            "backlight": {
              "format": "{icon}  {percent}%",
              "format-icons": [
                "󰃞",
                "󰃟",
                "󰃝",
                "󰃠"
              ],
              "on-scroll-down": "brightnessctl s 1%-",
              "on-scroll-up": "brightnessctl s +1%"
            },

            "battery": {
              "format": "{icon}  {capacity}%",
              "format-charging": "  {capacity}%",
              "format-icons": [
                "",
                "",
                "",
                "",
                ""
              ],
              "states": {
                "critical": 20
              },
              "tooltip": false
            },

            "clock": {
              "calendar": {
                "actions": {
                  "on-click-right": "mode",
                  "on-scroll-down": "shift_down",
                  "on-scroll-up": "shift_up"
                },
                "format": {
                  "days": "<span color='{color4}'><b>{}</b></span>",
                  "months": "<span color='{foreground}'><b>{}</b></span>",
                  "today": "<span color='{color3}'><b><u>{}</u></b></span>",
                  "weekdays": "<span color='{color5}'><b>{}</b></span>"
                },
                "mode": "year",
                "mode-mon-col": 3,
                "on-scroll": 1
              },
              "format": "{:%H:%M}",
              "format-alt": "{:%a, %d %b %Y}",
              "interval": 10,
              "tooltip-format": "<tt><small>{calendar}</small></tt>"
            },

            "hyprland/window": {
              "separate-outputs": true
            },

            "layer": "top",
            "margin": "4 4 0 4",

            "modules-center": [
              "wlr/workspaces"
            ],

            "modules-left": [
              "custom/nix",
              "hyprland/window"
            ],

            "modules-right": [ "network", "pulseaudio", "battery", "clock" ],

            "network": {
              "format-disconnected": "󰖪  Offline",
              "format-ethernet": "",
              "tooltip": false
            },

            "position": "top",

            "pulseaudio": {
              "format": "{icon}  {volume}%",
              "format-icons": [
                "",
                "",
                ""
              ],
              "format-muted": "󰸈 Muted",
              "on-click": "pamixer -t",
              "on-click-right": "pavucontrol",
              "scroll-step": 1,
              "tooltip": false
            },

            "wlr/workspaces": {
              "on-click": "activate",
              "sort-by-number": true
            },

            "custom/nix": {
              "format": "",
              "on-click": "hypr-wallpaper",
              // "on-click-right": "hypr-theme",
              "tooltip": false
            }${lib.optionalString (cfg.settings-template != "") ","}

            ${cfg.settings-template}
          }'';
        target = "~/.cache/wallust/waybar-config";
      };

      waybar-css = {
        enable = config.iynaix.wallust.waybar;
        text = lib.mkDefault ''
          #waybar {
            background: transparent;
          }

          #workspaces, #workspaces button, #battery, #network, #clock, #pulseaudio, #window, #backlight {
            font-family: "Inter", "FontAwesome6Free";
            font-weight: bold;
            color: {foreground};
            background-color: {color0};
            border-radius: 0;
            transition: none;
            padding: 0 8px;
          }

          #workspaces, #workspaces button {
            padding: 0 4px 0 4px;
            border-radius: 12px;
          }

          #clock, #workspaces button.active {
            background-color: {foreground};
            color: {color0};
            margin-right: 4px;
            border-radius: 0 12px 12px 0;
          }

          #custom-nix {
            background-color: {foreground};
            color: {color0};
            margin-left: 4px;
            padding: 0 12px;
            font-size: 16px;
            border-radius: 12px 0 0 12px;
          }

          #workspaces button.urgent {
            background-color: {color1};
            color: {foreground};
          }

          #pulseaudio, #backlight {
            padding: 0 12px;
          }

          #network {
            padding: 0 12px;
          }

          #network.disconnected, #battery.discharging.critical {
            color: {color1};
          }

          #window {
            padding: 0 12px;
            border-radius: 0 12px 12px 0;
          }

          #workspaces button.active {
            border-radius: 50%;
          }

          tooltip {
            background: {color0};
          }

          ${cfg.style-template}
        '';
        target = "~/.cache/wallust/waybar-style.css";
      };
    };

    iynaix.hyprland.extraBinds = lib.mkAfter {
      exec-once = ["${launch-waybar}/bin/launch-waybar"];
    };
  };
}
