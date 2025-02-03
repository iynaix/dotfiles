{ config, lib, ... }:
{
  options.custom = with lib; {
    framework_vertical.enable = mkEnableOption "framework vertical display";
  };

  config = {
    custom = {
      monitors =
        [
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
            name = "DP-4";
            width = 2560;
            height = 1440;
            position = "0x728";
            vertical = true;
            workspaces = [
              6
              7
            ];
            defaultWorkspace = 7;
          }
        ]
        ++ (
          if config.custom.framework_vertical.enable then
            [
              {
                name = "HDMI-A-1";
                width = 3840;
                height = 2160;
                position = "1754x0";
                scale = 2.0;
                workspaces = [
                  9
                ];
              }
              {
                name = "DP-3";
                width = 2256;
                height = 1504;
                position = "4880x1080";
                scale = 1.5;
                vertical = true;
                workspaces = [
                  8
                  10
                ];
                defaultWorkspace = 10;
              }
            ]
          else
            [
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
            ]
        );

      framework_vertical.enable = false;
      deadbeef.enable = true;
      ghostty.enable = true;
      hyprland = {
        plugin = "hyprnstack";
        lock = false;
        qtile = false;
      };
      modelling3d.enable = true;
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
  };
}
