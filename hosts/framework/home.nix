{ lib, pkgs, ... }:
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 2880;
        height = 1920;
        refreshRate = 120;
        scale = 2;
        vrr = true;
        workspaces = [
          1
          2
          3
          4
          5
          6
          7
          8
          9
          10
        ];
      }
    ];

    pathofbuilding.enable = true;
    rclip.enable = true;

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # don't blind me on startup
      "${lib.getExe pkgs.brightnessctl} s 25%"
    ];
  };
}
