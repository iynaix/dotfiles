{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}: let
  cfg = config.iynaix.waybar;
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    killall -q .waybar-wrapped

    waybar --config $HOME/.cache/wallust/waybar.jsonc \
        --style $HOME/.cache/wallust/waybar.css \
        > /dev/null 2>&1 &
  '';
in {
  config = lib.mkIf cfg.enable {
    home.packages = [launch-waybar];

    programs.waybar = {
      enable = isNixOS;
      # do not use the systemd service as it is flaky and unreliable
      # https://github.com/nix-community/home-manager/issues/3599
    };

    iynaix.waybar.config = {
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
        "hyprland/workspaces"
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

      "hyprland/workspaces" = {
        # TODO: pacman, remove active inverse circle
        # format = "{icon}";
        # format-icons = {
        #   active = "󰮯";
        #   default = "·";
        #   urgent = "󰊠";
        # };
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
    };

    iynaix.wallust.entries = let
      finalWaybarCfg =
        cfg.config
        // {
          # dedupe modules
          modules-left = lib.unique cfg.config.modules-left;
          modules-center = lib.unique cfg.config.modules-center;
          modules-right = lib.unique cfg.config.modules-right;
        };
    in {
      "waybar.jsonc" = {
        enable = config.iynaix.wallust.waybar;
        text = builtins.toJSON finalWaybarCfg;
        target = "~/.cache/wallust/waybar.jsonc";
      };
      "waybar.css" = let
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
        mkRadiusCss = arr: let
          last = builtins.length arr - 1;
        in
          lib.concatStringsSep "\n" (
            lib.imap0 (i: mod: let
              className = builtins.replaceStrings ["hyprland/" "/"] ["" "-"] mod;
              left =
                if i == 0
                then radius
                else "0";
              right =
                if i == last
                then radius
                else "0";
            in ''#${className} { border-radius: ${left} ${right} ${right} ${left}; }'')
            arr
          );
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
            transition: none;
            padding: 0 8px;
          }

          #workspaces, #workspaces button {
            padding: 0 4px 0 4px;
          }

          #clock, #workspaces button.active {
            background-color: {foreground};
            color: {color0};
            margin-right: 4px;
          }

          #custom-nix {
            background-color: {foreground};
            color: {color0};
            margin-left: 4px;
            padding: 0 16px 0 12px;
            font-size: 16px;
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

          ${mkRadiusCss finalWaybarCfg.modules-left}
          ${mkRadiusCss finalWaybarCfg.modules-center}
          ${mkRadiusCss finalWaybarCfg.modules-right}

          ${cfg.css}
        '';
        target = "~/.cache/wallust/waybar.css";
      };
    };
  };
}
