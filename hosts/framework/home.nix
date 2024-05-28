{ lib, pkgs, ... }:
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 2256;
        height = 1504;
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

    terminal.size = 12;

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
