{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.pathofbuilding;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.iynaix.path-of-building];

    wayland.windowManager.hyprland.settings = {
      # starts floating for some reason?
      windowrulev2 = ["tile,class:(pobfrontend)"];
    };

    iynaix.persist = {
      home.directories = [
        ".local/share/pobfrontend"
      ];
    };
  };
}
