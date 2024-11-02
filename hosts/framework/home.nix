{ lib, pkgs, ... }:
{
  custom = {
    monitors = [
      {
        name = "eDP-1";
        width = 2880;
        height = 1920;
        refreshRate = 120;
        scale = 2;
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

    pathofbuilding.enable = true;
    rclip.enable = true;
    waybar.hidden = true;

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # don't blind me on startup
      "${lib.getExe pkgs.brightnessctl} s 25%"
    ];
  };

  # improve framework speaker audio quality
  # https://reddit.com/r/framework/comments/18cngrn/
  services.easyeffects = {
    enable = true;
    preset = "kieran_levin";
  };

  xdg.configFile."easyeffects/output".source = pkgs.fetchFromGitHub {
    owner = "ceiphr";
    repo = "ee-framework-presets";
    rev = "27885fe00c97da7c441358c7ece7846722fd12fa";
    hash = "sha256-z2WmozMDMUkiAd+BEc/5+DHgFXDbw3FdsvBwgIj0JmI=";
  };
}
