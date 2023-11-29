{
  lib,
  config,
  isNixOS,
  ...
}: let
  cfg = config.iynaix;
in {
  imports = [
    ./split.nix
    ./transparent.nix
  ];

  config = lib.mkIf cfg.waybar.enable {
    programs.waybar = {
      enable = isNixOS;
      # do not use the systemd service as it is flaky and unreliable
      # https://github.com/nix-community/home-manager/issues/3599
    };

    iynaix.waybar.config = {
      backlight = lib.mkIf cfg.backlight.enable {
        format = "{icon}  {percent}%";
        format-icons = ["󰃞" "󰃟" "󰃝" "󰃠"];
        on-scroll-down = "brightnessctl s 1%-";
        on-scroll-up = "brightnessctl s +1%";
      };

      battery = lib.mkIf cfg.battery.enable {
        format = "{icon}  {capacity}%";
        format-charging = "  {capacity}%";
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

      modules-right =
        ["network" "pulseaudio"]
        ++ (lib.optionals cfg.backlight.enable ["backlight"])
        ++ (lib.optionals cfg.battery.enable ["battery"])
        ++ ["clock"];

      network =
        if cfg.wifi.enable
        then {
          format = "  {essid}";
          format-disconnected = "󰖪  Offline";
          on-click = "~/.config/rofi/rofi-wifi-menu";
          on-click-right = "${config.iynaix.terminal.exec} nmtui";
          tooltip = false;
        }
        else {
          format-disconnected = "󰖪  Offline";
          format-ethernet = "";
          tooltip = false;
        };

      position = "top";

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-icons = ["󰕿" "󰖀" "󰕾"];
        format-muted = "󰖁  Muted";
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
        format = "󱄅";
        on-click = "hypr-wallpaper";
        on-click-right = "imv-wallpaper";
        tooltip = false;
      };
    };

    iynaix.wallust.entries = {
      "waybar.jsonc" = {
        enable = cfg.waybar.enable;
        text = builtins.toJSON cfg.waybar.config;
        target = "~/.config/waybar/config";
      };
    };
  };
}
