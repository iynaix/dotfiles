{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  flake.modules.nixos.core =
    { config, ... }:
    {
      options.custom = {
        programs.pathofbuilding.enable = mkEnableOption "pathofbuilding" // {
          default = config.custom.wm != "tty";
        };
      };
    };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    mkIf config.custom.programs.pathofbuilding.enable {
      environment.systemPackages = [ pkgs.custom.path-of-building ];

      custom.programs.hyprland.settings = {
        # starts floating for some reason?
        windowrule = [ "tile,class:(pobfrontend)" ];
      };

      custom.persist = {
        home.directories = [ ".local/share/pobfrontend" ];
      };
    };
}
