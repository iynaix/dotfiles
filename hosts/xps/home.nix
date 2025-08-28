{ config, ... }:
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 1920;
        height = 1080;
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
        refreshRate = if config.custom.wm == "hyprland" then "60" else "59.934";
      }
    ];

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

  programs.btop.settings = {
    custom_gpu_name0 = "Intel HD Graphics 5500";
  };
}
