{...}: {
  iynaix = {
    displays = [
      {
        name = "eDP-1";
        hyprland = "1920x1080,0x0,1";
        workspaces = [1 2 3 4 5 6 7 8 9 10];
      }
    ];

    pathofbuilding.enable = true;

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
      };
    };

    terminal.size = 10;

    persist = {
      home.directories = [
        {
          directory = "Downloads";
          method = "symlink";
        }
      ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    gestures = {
      workspace_swipe = true;
    };

    # backlight
    bind = [
      ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
    ];

    # handle laptop lid
    bindl = [
      # ",switch:on:Lid Switch, exec, hyprctl keyword monitor ${displayCfg.monitor1}, 1920x1080, 0x0, 1"
      # ",switch:off:Lid Switch, exec, hyprctl monitor ${displayCfg.monitor1}, disable"
      ",switch:Lid Switch, exec, hypr-lock"
    ];
  };
}
