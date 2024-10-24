_: {
  custom = {
    monitors = [
      {
        name = "DP-2";
        width = 3440;
        height = 1440;
        refreshRate = 144;
        vrr = true;
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
        width = 3840;
        height = 2160;
        position = "1754x0";
        scale = 2;
        workspaces = [
          8
          9
          10
        ];
      }
    ];

    deadbeef.enable = true;
    ghostty.enable = false;
    hyprland = {
      plugin = "hyprnstack";
      lock = false;
      qtile = false;
    };
    obs-studio.enable = false;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = true;
    wallpaper-utils.enable = true;
    # wallust.colorscheme = "tokyo-night";
    waybar = {
      enable = true;
      hidden = false;
      # waybar.persistentWorkspaces = true;
    };
  };

  # build package for testing, but it isn't used
  # home.packages = [ pkgs.hyprlock ];
}
