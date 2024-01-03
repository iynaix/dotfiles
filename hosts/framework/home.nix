{
  lib,
  pkgs,
  ...
}: {
  iynaix = {
    displays = [
      {
        name = "eDP-1";
        hyprland = "2256x1504,0x0,1";
        workspaces = [1 2 3 4 5 6 7 8 9 10];
      }
    ];

    # hardware
    backlight.enable = true;
    battery.enable = true;
    wezterm.enable = false;
    wifi.enable = true;

    pathofbuilding.enable = true;

    terminal.size = 12;

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
    exec-once = [
      # don't blind me on startup
      "${lib.getExe pkgs.brightnessctl} s 25%"
    ];
  };
}
