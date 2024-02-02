{
  lib,
  config,
  isNixOS,
  pkgs,
  ...
}: let
  cfg = config.custom.waybar;
in
  lib.mkIf cfg.enable {
    programs.waybar = {
      enable = isNixOS;
      # do not use the systemd service as it is flaky and unreliable
      # https://github.com/nix-community/home-manager/issues/3599
    };

    custom.waybar.config = {
      backlight = lib.mkIf config.custom.backlight.enable {
        format = "{icon}   {percent}%";
        format-icons = ["󰃞" "󰃟" "󰃝" "󰃠"];
        on-scroll-down = "${lib.getExe pkgs.brightnessctl} s 1%-";
        on-scroll-up = "${lib.getExe pkgs.brightnessctl} s +1%";
      };

      battery = lib.mkIf config.custom.battery.enable {
        format = "{icon}    {capacity}%";
        format-charging = "     {capacity}%";
        format-icons = ["" "" "" "" ""];
        states = {
          critical = 20;
        };
        tooltip = false;
      };

      clock = {
        calendar = {
          actions = {
            on-click-right = "mode";
            on-scroll-down = "shift_down";
            on-scroll-up = "shift_up";
          };
          format = {
            days = "<span color='{{color4}}'><b>{}</b></span>";
            months = "<span color='{{foreground}}'><b>{}</b></span>";
            today = "<span color='{{color3}}'><b><u>{}</u></b></span>";
            weekdays = "<span color='{{color5}}'><b>{}</b></span>";
          };
          mode = "year";
          mode-mon-col = 3;
          on-scroll = 1;
        };
        format = "󰥔   {:%H:%M}";
        format-alt = "󰸗   {:%a, %d %b %Y}";
        # format = "󰥔   {:%H:%M}";
        # format-alt = "  {:%a, %d %b %Y}";
        interval = 10;
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "custom/nix" = {
        format = "󱄅";
        on-click = "hypr-wallpaper";
        on-click-right = "imv-wallpaper";
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

      "hyprland/window" = {
        rewrite = {
          # strip the application name
          "(.*) - (.*)" = "$1";
        };
        separate-outputs = true;
      };

      layer = "top";
      margin = "0";

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-left = [
        "custom/nix"
        # "hyprland/window"
      ];

      modules-right =
        ["network" "pulseaudio"]
        ++ (lib.optional config.custom.backlight.enable "backlight")
        ++ (lib.optional config.custom.battery.enable "battery")
        ++ ["clock"];

      network =
        if config.custom.wifi.enable
        then {
          format = "    {essid}";
          format-disconnected = "󰖪    Offline";
          on-click = "${config.xdg.configHome}/rofi/rofi-wifi-menu";
          on-click-right = "${config.custom.terminal.exec} nmtui";
          tooltip = false;
        }
        else {
          format-disconnected = "󰖪    Offline";
          format-ethernet = "";
          tooltip = false;
        };

      position = "top";

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-icons = ["󰕿" "󰖀" "󰕾"];
        format-muted = "󰖁  Muted";
        on-click = "${lib.getExe pkgs.pamixer} -t";
        on-click-right = "pavucontrol";
        scroll-step = 1;
        tooltip = false;
      };

      start_hidden = cfg.hidden;
    };

    custom.wallust.templates = {
      "waybar.jsonc" = {
        inherit (cfg) enable;
        text = lib.strings.toJSON cfg.config;
        target = "${config.xdg.configHome}/waybar/config";
      };
      "waybar.css" = let
        baseModuleCss = ''
          font-family: ${config.custom.fonts.regular};
          font-weight: bold;
          color: {{foreground}};
          transition: none;
          text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
          border-bottom:  2px solid transparent;
        '';
        mkModuleCss = arr: let
          last = lib.length arr - 1;
        in
          lib.concatStringsSep "\n" (
            lib.imap0 (i: mod: let
              className = lib.replaceStrings ["hyprland/" "/"] ["" "-"] mod;
              padding =
                if (i == 0)
                then ''
                  padding-right: 12px;
                ''
                else if (i == last)
                then ''
                  padding-left: 12px;
                ''
                else ''
                  padding-left: 12px;
                  padding-right: 12px;
                '';
            in ''
              #${className} {
                ${baseModuleCss}
                ${padding}
              }'')
            arr
          );
      in {
        inherit (cfg) enable;
        text = ''
          * {
            border: none;
            border-radius: 0;
          }

          #waybar {
            background: rgba(0,0,0,0.5)
          }

          ${mkModuleCss cfg.config.modules-left}
          ${mkModuleCss cfg.config.modules-center}
          ${mkModuleCss cfg.config.modules-right}

          #workspaces button {
            ${baseModuleCss}
          }

          #custom-nix {
            margin-left: 12px;
            font-size: 20px;
          }

          #clock{
            margin-right: 12px;
          }

          #workspaces button.active {
            margin-right: 4px;
            border-bottom:  2px solid {{foreground}};
            background-color: rgba(255,255,255, 0.25);
          }
        '';
        target = "${config.xdg.configHome}/waybar/style.css";
      };
    };
  }
