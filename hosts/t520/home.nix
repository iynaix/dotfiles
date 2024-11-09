_: {
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 1920;
        height = 1080;
        refreshRate = 60;
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
    ghostty.enable = false;
    hyprland = {
      plugin = "hyprnstack";
      lock = false;
      qtile = false;
    };
    obs-studio.enable = false;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = false;
    wallfacer.enable = true;
    # wallust.colorscheme = "tokyo-night";
    waybar = {
      enable = true;
      hidden = false;
      # waybar.persistentWorkspaces = true;
    };
  };

  # home = {
  #   packages = with pkgs; [
  #     # hyprlock # build package for testing, but it isn't used
  #   ];
  # };
}