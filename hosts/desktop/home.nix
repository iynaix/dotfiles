_: {
  custom = {
    monitors = [
      {
        name = "DP-2";
        width = 3440;
        height = 1440;
        # niri wants this to be exact down to the decimals
        # refreshRate = if config.custom.wm == "hyprland" then 144 else "143.975";
        vrr = false;
        position-x = 1440;
        position-y = 1080;
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
        position-x = 0;
        position-y = 728;
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
        position-x = 1754;
        position-y = 0;
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
      #   position-x = 4880;
      #   position-y = 1080;
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
      qtile = false;
    };
    lock.enable = false;
    modelling3d.enable = true;
    niri.blur.enable = false;
    nvidia.enable = true;
    printing3d.enable = true;
    obs-studio.enable = false;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = true;
    wallfacer.enable = true;
    wallpaper-tools.enable = true;
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
