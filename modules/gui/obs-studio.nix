{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    programs.obs-studio.enable = mkEnableOption "obs-studio";
  };

  config = mkIf config.custom.programs.obs-studio.enable {
    programs.obs-studio.enable = true;

    custom.persist = {
      home.directories = [ ".config/obs-studio" ];
    };
  };
}
