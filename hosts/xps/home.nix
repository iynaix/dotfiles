{...}: {
  iynaix = {
    displays = [
      {
        name = "eDP-1";
        hyprland = "1920x1080,0x0,1";
        workspaces = [1 2 3 4 5 6 7 8 9 10];
      }
    ];

    # hardware
    backlight.enable = true;
    battery.enable = true;
    wifi.enable = true;

    pathofbuilding.enable = true;
    wezterm.enable = false;

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

    # handle laptop lid
    bindl = [
      # ",switch:on:Lid Switch, exec, hyprctl keyword monitor ${displayCfg.monitor1}, 1920x1080, 0x0, 1"
      # ",switch:off:Lid Switch, exec, hyprctl monitor ${displayCfg.monitor1}, disable"
      ",switch:Lid Switch, exec, hypr-lock"
    ];
  };
}
