{ lib, pkgs, ... }:
{
  custom = {
    displays = [
      {
        name = "eDP-1";
        hyprland = "2256x1504,0x0,1";
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
