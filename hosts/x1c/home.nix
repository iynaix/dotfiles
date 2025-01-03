{
  config,
  lib,
  pkgs,
  ...
}:
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 1920;
        height = 1080;
        refreshRate = if config.specialisation == "otg" then 120 else 60;
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

    deadbeef.enable = true;
    gaming.enable = false;
    ghostty.enable = true;
    helix.enable = false;
    pathofbuilding.enable = true;
    rclip.enable = true;
    wallfacer.enable = true;

    terminal.size = 12;

    persist = {
      home.directories = [
        "Downloads"
        "Music"
      ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # don't blind me on startup
      "${lib.getExe pkgs.brightnessctl} s 50%"
    ];
  };
}
