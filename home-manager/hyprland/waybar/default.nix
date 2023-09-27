{
  lib,
  config,
  isNixOS,
  ...
}: let
  cfg = config.iynaix.waybar;
in {
  imports = [
    ./split.nix
    ./transparent.nix
  ];

  config = lib.mkIf cfg.enable {
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
        format = "";
        on-click = "hypr-wallpaper";
        on-click-right = "imv-wallpaper";
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

    iynaix.wallust.entries = {
      "waybar.jsonc" = {
        enable = config.iynaix.wallust.waybar;
        text = builtins.toJSON cfg.finalConfig;
        target = "~/.config/waybar/config";
      };
    };
  };
}
