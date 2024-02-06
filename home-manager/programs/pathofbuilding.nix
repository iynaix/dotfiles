{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkIf config.custom.pathofbuilding.enable {
  home.packages = [ pkgs.custom.path-of-building ];

  wayland.windowManager.hyprland.settings = {
    # starts floating for some reason?
    windowrulev2 = [ "tile,class:(pobfrontend)" ];
  };

  custom.persist = {
    home.directories = [ ".local/share/pobfrontend" ];
  };
}
