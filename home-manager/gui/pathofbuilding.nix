{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    pathofbuilding.enable = mkEnableOption "pathofbuilding" // {
      default = isNixOS && !config.custom.headless;
    };
  };

  config = lib.mkIf config.custom.pathofbuilding.enable {
    home.packages = [ pkgs.path-of-building ];

    wayland.windowManager.hyprland.settings = {
      # starts floating for some reason?
      windowrulev2 = [ "tile,class:(pobfrontend)" ];
    };

    custom.persist = {
      home.directories = [ ".local/share/pobfrontend" ];
    };
  };
}
