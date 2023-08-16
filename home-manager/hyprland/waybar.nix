{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}: let
  cfg = config.iynaix.waybar;
  reload-waybar = pkgs.writeShellScriptBin "reload-waybar" ''
    killall -q -SIGUSR2 .waybar-wrapped
  '';
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    killall -q .waybar-wrapped
    waybar > /dev/null 2>&1 &
  '';
in {
  config = lib.mkIf cfg.enable {
    home.packages = [launch-waybar reload-waybar];

    programs.waybar = {
      enable = isNixOS;
      # do not use the systemd service as it is flaky and unreliable
      # https://github.com/nix-community/home-manager/issues/3599

      # use patched waybar from hyprland
      package = pkgs.waybar.override {hyprlandSupport = true;};
      # .overrideAttrs (oldAttrs: {
      #     # use latest waybar from git
      #   src = pkgs.fetchgit {
      #     url = "https://github.com/Alexays/Waybar";
      #     rev = "0.9.20";
      #     sha256 = "sha256-aViAMgZzxmXrZhIXD15TwbJeF9PpRwKIDadjeKhB2hE=";
      #   };
      # });
    };

    iynaix.wallust.entries = {
      waybar-config = {
        enable = config.iynaix.wallust.waybar;
        text = builtins.toJSON ({
            clock = {
              calendar = {
                actions = {
                  on-click-right = "mode";
                  on-scroll-down = "shift_down";
                  on-scroll-up = "shift_up";
                };
                format = {
                  days = "<span color='{color4}'><b>{}</b></span>";
                  months = "<span color='{foreground}'><b>{}</b></span>";
                  today = "<span color='{color3}'><b><u>{}</u></b></span>";
                  weekdays = "<span color='{color5}'><b>{}</b></span>";
                };
                mode = "year";
                mode-mon-col = 3;
                on-scroll = 1;
              };
              format = "{:%H:%M}";
              format-alt = "{:%a, %d %b %Y}";
              # format = "󰥔   {:%H:%M}";
              # format-alt = "  {:%a, %d %b %Y}";
              interval = 10;
              tooltip-format = "<tt><small>{calendar}</small></tt>";
            };

            "hyprland/window" = {
              rewrite = {
                # strip the application name
                "(.*) - (.*)" = "$1";
              };
              separate-outputs = true;
            };

            layer = "top";
            margin = "4 4 0 4";

            modules-center = [
              "wlr/workspaces"
            ];

            modules-left = [
              "custom/nix"
              # "hyprland/window"
            ];

            modules-right = ["pulseaudio" "network" "battery" "clock"];

            network = {
              format-disconnected = "󰖪  Offline";
              format-ethernet = "";
              tooltip = false;
            };

            position = "top";

            pulseaudio = {
              format = "{icon}  {volume}%";
              format-icons = ["" "" ""];
              format-muted = "󰸈 Muted";
              on-click = "pamixer -t";
              on-click-right = "pavucontrol";
              scroll-step = 1;
              tooltip = false;
            };

            "wlr/workspaces" = {
              on-click = "activate";
              sort-by-number = true;
            };

            "custom/nix" = {
              format = "";
              on-click = "hypr-wallpaper";
              on-click-right = "hypr-wallpaper --rofi wallpaper";
              tooltip = false;
            };

            # custom separators for future use
            # "custom/separator-bl" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
            # "custom/separator-br" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
            # "custom/separator-tl" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
            # "custom/separator-tr" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
            # "custom/separator-right-triangle" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
            # "custom/separator-left-triangle" = {
            #   "format" = "";
            #   "tooltip" = false;
            # };
          }
          // cfg.config);
        target = "~/.config/waybar/config";
      };

      waybar-css = let
        separatorClass = {
          name,
          color,
          background-color,
          inverse ? false,
        }: let
          finalColor =
            if color
            then color
            else
              (
                if inverse
                then "background"
                else "color0"
              );
          finalBackgroundColor =
            if background-color
            then background-color
            else
              (
                if inverse
                then "color0"
                else "background"
              );
        in ''
          #custom-separator-${name} {
            color: {${finalColor}};
            background-color: {${finalBackgroundColor}};
            font-size: 18px;
            font-family: "${config.iynaix.fonts.monospace}";
            margin-top: -1px;
          }
        '';
        radius = config.iynaix.waybar.border-radius;
      in {
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
            border-radius: ${radius};
          }

          #clock, #workspaces button.active {
            background-color: {foreground};
            color: {color0};
            margin-right: 4px;
            border-radius: 0 ${radius} ${radius} 0;
          }

          #custom-nix {
            background-color: {foreground};
            color: {color0};
            margin-left: 4px;
            padding: 0 16px 0 12px;
            font-size: 16px;

            /* with hyprland / window */
            /* border-radius: ${radius} 0 0 ${radius}; */

            /* standalone */
            border-radius: ${radius};
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
            border-radius: 0 ${radius} ${radius} 0;
          }

          /* invert colors for monocle / swallowing */
          window#waybar.fullscreen #window, window#waybar.swallowing #window, window#waybar.hidden #window {
              background-color: {foreground};
              color: {color0};
          }

          #workspaces button.active {
            border-radius: 50%;
          }

          tooltip {
            background: {color0};
          }

          ${cfg.css}
        '';
        target = "~/.config/waybar/style.css";
      };
    };
  };
}
