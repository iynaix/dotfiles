{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.waybar;
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    killall -q .waybar-wrapped
    waybar > /dev/null 2>&1 &
  '';
in
{
  options.iynaix.waybar = {
    style = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Additional waybar css styles as lines";
    };
  };

  config = lib.mkIf config.iynaix.hyprland.enable {
    home-manager.users.${user} = {
      home.packages = with pkgs; [ pavucontrol launch-waybar ];

      programs.waybar = {
        enable = true;
        package = pkgs.hyprland.waybar-hyprland;
        settings = [{
          layer = "top";
          position = "top";
          margin = "4 4 0 4";
          modules-left = [ "hyprland/window" ];
          modules-center = [ "wlr/workspaces" ];
          modules-right = [ "network" "pulseaudio" "battery" "clock" ];
          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%a, %d %b %Y}";
            interval = 10;
          };
          "hyprland/window" = {
            separate-outputs = true;
          };
          network = {
            tooltip = false;
            format-ethernet = "";
            format-disconnected = "<span color=\"#4a4a4a\"></span>";
            format-wifi = "";
          };
          pulseaudio = {
            format = "{icon}";
            format-muted = "<span color=\"#4a4a4a\"></span>";
            format-icons = [ "" "" ];
            on-click = "pavucontrol";
            tooltip = true;
            tooltip-format = "{volume}%";
          };
          battery = {
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-icons = [ "" "" "" "" "" ];
            tooltip = false;
          };
          "custom/power" = {
            format = "";
            on-click = "rofi -show power-menu -modi power-menu:~/.config/rofi/scripts/rofi-power-menu -theme ~/.config/rofi/powermenu.rasi";
            tooltip = false;
          };
          "wlr/workspaces" = {
            on-click = "activate";
            sort-by-number = true;
          };
        }];
        style = with config.iynaix.xrdb; ''
          #waybar {
            background: transparent;
          }
          #workspaces, #workspaces button, #battery, #network, #clock, #pulseaudio, #window {
            font-family: "Inter", "FontAwesome6Free";
            font-weight: bold;
            color: ${foreground};
            background-color: ${color0};
            border-radius: 0;
            transition: none;
            padding: 0 8px;
          }
          #workspaces, #workspaces button {
            padding: 0 4px 0 4px;
            border-radius: 12px;
          }
          #clock, #workspaces button.active {
            background-color: ${foreground};
            color: ${color0};
            margin-right: 4px;
            border-radius: 0 12px 12px 0;
          }
          #pulseaudio {
            padding: 0 12px;
          }
          #network {
            padding: 0 12px;
          }
          #network.disconnected {
            color: ${color1};
          }
          #window {
            margin-left: 4px;
            border-radius: 12px;
          }
          #workspaces button.active {
            border-radius: 50%;
          }
        '' + (lib.concatStringsSep "\n" cfg.style);
      };

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter "exec-once = ${launch-waybar}/bin/launch-waybar";
    };
  };
}
