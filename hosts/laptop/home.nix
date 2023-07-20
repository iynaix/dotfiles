{config, ...}: let
  displayCfg = config.iynaix.displays;
in {
  iynaix = {
    displays.monitor1 = "eDP-1";
    pathofbuilding.enable = true;

    hyprland = {
      enable = true;
      monitors = ''
        monitor = ${displayCfg.monitor1}, 1920x1080,0x0,1
      '';
      extraVariables = ''
        gestures {
          workspace_swipe = true
        }
      '';
      extraBinds = {
        # backlight
        bind = {
          ",XF86MonBrightnessDown" = "exec, brightnessctl set 5%-";
          ",XF86MonBrightnessUp" = "exec, brightnessctl set +5%";
        };

        # handle laptop lid
        bindl = {
          # ",switch:on:Lid Switch" = ''exec, hyprctl keyword monitor "${displayCfg.monitor1}, 1920x1080, 0x0, 1"'';
          # ",switch:off:Lid Switch" = ''exec, hyprctl monitor "${displayCfg.monitor1}, disable"'';
          ",switch:Lid Switch" = "exec, hypr-lock";
        };
      };
    };

    terminal.size = 10;

    waybar = {
      config = {
        backlight = {
          format = "{icon}  {percent}%";
          format-icons = ["󰃞" "󰃟" "󰃝" "󰃠"];
          on-scroll-down = "brightnessctl s 1%-";
          on-scroll-up = "brightnessctl s +1%";
        };
        battery = {
          format = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-icons = ["" "" "" "" ""];
          states = {
            critical = 20;
          };
          tooltip = false;
        };
        modules-right = ["network" "pulseaudio" "backlight" "battery" "clock"];
        network = {
          format = "  {essid}";
          format-disconnected = "󰖪  Offline";
          on-click = "~/.config/rofi/rofi-wifi-menu";
          on-click-right = "${config.iynaix.terminal.exec} nmtui";
          tooltip = false;
        };
      };
      # add rounded corners for leftmost modules-right
      css = let
        radius = config.iynaix.waybar.border-radius;
      in ''
        #network {
          border-radius: ${radius} 0 0 ${radius};
        }
      '';
    };
  };
}
