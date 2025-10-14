{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.obs-studio.enable = mkEnableOption "obs-studio";
    };
  };

  flake.modules.nixos.gui =
    { config, ... }:
    mkIf config.custom.programs.obs-studio.enable {
      programs.obs-studio.enable = true;

      custom.persist = {
        home.directories = [ ".config/obs-studio" ];
      };
    };
}
