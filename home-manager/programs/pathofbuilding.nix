{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.pathofbuilding;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.custom.path-of-building];

    wayland.windowManager.hyprland.settings = {
      # starts floating for some reason?
      windowrulev2 = ["tile,class:(pobfrontend)"];
    };

    custom.persist = {
      home.directories = [
        ".local/share/pobfrontend"
      ];
    };
  };
}
