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
    specialisation = {
      hyprland.enable = true;
    };

    monitors = [
      {
        name = "eDP-1";
        width = 2880;
        height = 1920;
        # 60.001 for 60 fps
        refreshRate = if config.custom.wm == "hyprland" then "120" else "120.000";
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

    # don't blind me on startup
    startup = [
      {
        spawn = [
          (getExe pkgs.brightnessctl)
          "s"
          "20%"
        ];
      }
    ];

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

}
