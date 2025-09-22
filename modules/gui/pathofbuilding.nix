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
    programs.pathofbuilding.enable = mkEnableOption "pathofbuilding" // {
      default = isNixOS && config.hm.custom.wm != "tty";
    };
  };

  config = mkIf config.custom.programs.pathofbuilding.enable {
    environment.systemPackages = [ pkgs.custom.path-of-building ];

    hm.wayland.windowManager.hyprland.settings = {
      # starts floating for some reason?
      windowrule = [ "tile,class:(pobfrontend)" ];
    };

    custom.persist = {
      home.directories = [ ".local/share/pobfrontend" ];
    };
  };
}
