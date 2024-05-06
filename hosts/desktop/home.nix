{
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  custom = {
    displays = [
      {
        name = "DP-2";
        hyprland = "3440x1440@144,1440x1080,1";
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
        hyprland = "2560x1440,0x728,1,transform,1";
        workspaces = [
          6
          7
        ];
      }
      {
        name = "HDMI-A-1";
        hyprland = "1920x1080,1754x0,1";
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
        ffmpeg
        hyprlock # build package for testing, but it isn't used
        # vial
      ]
    );
  };
}
