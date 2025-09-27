{ config, ... }:
{
  custom = {
    specialisation = {
      hyprland.enable = true;
      mango.enable = false;
    };

    monitors = [
      {
        name = "DP-2";
        width = 3440;
        height = 1440;
        # niri / mango wants this to be exact down to the decimals
        refreshRate = if config.custom.wm == "hyprland" then "144" else "174.963";
        vrr = false;
        positionX = 1440;
        positionY = 1080;
        workspaces = [
          1
          2
          3
          4
          5
        ];
        extraHyprlandConfig = {
          supports_hdr = 1;
          bitdepth = 10;
        };
      }
      {
        name = "DP-1";
        width = 2560;
        height = 1440;
        positionX = 0;
        positionY = 728;
        transform = 1;
        workspaces = [
          6
          7
        ];
        defaultWorkspace = 7;
        refreshRate = "59.951";
      }
      {
        name = "HDMI-A-1";
        width = 3840;
        height = 2160;
        positionX = 1754;
        positionY = 0;
        scale = 2.0;
        workspaces = [
          8
          9
          10
        ];
        defaultWorkspace = 9;
        refreshRate = "59.997";
      }
      # {
      #   name = "DP-3";
      #   width = 2256;
      #   height = 1504;
      #   positionX = 4880;
      #   positionY = 1080;
      #   scale = 1.5666666666666666; # 47/30
      #   transform = 3;
      #   workspaces = [
      #     8
      #     10
      #   ];
      #   defaultWorkspace = 10;
      # }
    ];

    niri.blur.enable = false;
    nvidia.enable = true;
    # wallust.colorscheme = "tokyo-night";
  };
}
