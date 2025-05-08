_: {
  custom = {
    monitors = [
      {
        name = "DP-2";
        width = 3440;
        height = 1440;
        refreshRate = 144;
        # vrr = true;
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
        name = "DP-1";
        width = 2560;
        height = 1440;
        position = "0x728";
        transform = 1;
        workspaces = [
          6
          7
        ];
        defaultWorkspace = 7;
      }
      {
        name = "HDMI-A-1";
        width = 3840;
        height = 2160;
        position = "1754x0";
        scale = 2.0;
        workspaces = [
          8
          9
          10
        ];
        defaultWorkspace = 9;
      }
      # {
      #   name = "DP-3";
      #   width = 2256;
      #   height = 1504;
      #   position = "4880x1080";
      #   scale = 1.5666666666666666; # 47/30
      #   transform = 3;
      #   workspaces = [
      #     8
      #     10
      #   ];
      #   defaultWorkspace = 10;
      # }
    ];

    deadbeef.enable = true;
    ghostty.enable = true;
    hyprland = {
      hyprnstack = true;
      lock = false;
      qtile = false;
    };
    modelling3d.enable = true;
    nvidia.enable = true;
    printing3d.enable = true;
    obs-studio.enable = false;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = true;
    wallfacer.enable = true;
    wallpaper-extras.enable = true;
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
