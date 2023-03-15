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
    settings = lib.mkOption {
      default = { };
      description = "Additional waybar settings";
    };
    style = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      description = "Additional waybar css styles as lines";
    };
  };

  config = lib.mkIf config.iynaix.hyprland.enable {
    home-manager.users.${user} = {
      home.packages = [ launch-waybar ];

      programs.waybar = {
        enable = true;
        package = pkgs.hyprland.waybar-hyprland;
        settings = [
          ({
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
              format-ethernet = "";
              format-disconnected = "睊  Offline";
              tooltip = false;
            };
            pulseaudio = {
              format = "{icon}  {volume}%";
              scroll-step = 1;
              format-muted = "婢 Muted";
              format-icons = [ "" "" "" ];
              on-click = "pamixer -t";
              on-click-right = "pavucontrol";
              tooltip = false;
            };
            battery = {
              format = "{icon}  {capacity}%";
              format-charging = "  {capacity}%";
              format-icons = [ "" "" "" "" "" ];
              states = {
                critical = 20;
              };
              tooltip = false;
            };
            backlight = {
              format = "{icon}  {percent}%";
              format-icons = [ "󰃞" "󰃟" "󰃝" "" ];
              on-scroll-up = "brightnessctl s +1%";
              on-scroll-down = "brightnessctl s 1%-";
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
          } // cfg.settings)
        ];
        style = with config.iynaix.xrdb; ''
          #waybar {
            background: transparent;
          }
          #workspaces, #workspaces button, #battery, #network, #clock, #pulseaudio, #window, #backlight {
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
          #workspaces button.urgent {
            background-color: ${foreground};
            color: ${color1};
            margin-right: 4px;
            border-radius: 0 12px 12px 0;
          }
          #pulseaudio, #backlight {
            padding: 0 12px;
          }
          #network {
            padding: 0 12px;
          }
          #network.disconnected, #battery.discharging.critical {
            color: ${color1};
          }
          #window {
            margin-left: 4px;
            border-radius: 12px;
          }
          #workspaces button.active {
            border-radius: 50%;
          }
        '' + "\n" + cfg.style;
      };

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter
        "exec-once = ${launch-waybar}/bin/launch-waybar";
    };
  };
}
