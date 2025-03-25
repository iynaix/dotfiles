{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    pathofbuilding.enable = mkEnableOption "pathofbuilding" // {
      default = isNixOS && !config.custom.headless;
    };
  };

  config = mkIf config.custom.pathofbuilding.enable {
    home.packages = [ pkgs.path-of-building ];

    wayland.windowManager.hyprland.settings = {
      # starts floating for some reason?
      windowrule = [ "tile,class:(pobfrontend)" ];
    };

    custom.persist = {
      home.directories = [ ".local/share/pobfrontend" ];
    };
  };
}
