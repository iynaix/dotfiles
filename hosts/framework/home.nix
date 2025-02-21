{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
in
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 2880;
        height = 1920;
        refreshRate = if config.specialisation == "otg" then 120 else 60;
        scale = 1.5;
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

    modelling3d.enable = true;
    printing3d.enable = true;
    pathofbuilding.enable = true;
    rclip.enable = true;
    wallfacer.enable = true;
    waybar.hidden = true;

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # don't blind me on startup
      "${getExe pkgs.brightnessctl} s 20%"
    ];
  };
}
