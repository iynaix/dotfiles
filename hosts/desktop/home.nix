{
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  custom = {
    monitors = [
      {
        name = "DP-2";
        width = 3440;
        height = 1440;
        refreshRate = 144;
        position = "1440x1080";
        workspaces = [
          1
          2
          3
          4
          5
        ];
      }
      {
        name = "DP-4";
        width = 2560;
        height = 1440;
        position = "0x728";
        vertical = true;
        workspaces = [
          6
          7
        ];
      }
      {
        name = "HDMI-A-1";
        width = 1920;
        height = 1080;
        position = "1754x0";
        workspaces = [
          8
          9
          10
        ];
      }
    ];

    deadbeef.enable = true;
    ghostty.enable = true;
    hyprland = {
      plugin = "hyprnstack";
      lock = false;
      qtile = false;
    };
    obs-studio.enable = true;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = true;
    wallpaper-pipeline.enable = true;
    # wallust.colorscheme = "tokyo-night";
    # waybar.persistent-workspaces = true;
    waybar.hidden = false;
  };

  home = {
    packages = lib.mkIf isNixOS (
      with pkgs;
      [
        hyprlock # build package for testing, but it isn't used
        # vial
      ]
    );
  };
}
