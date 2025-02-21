{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    obs-studio.enable = mkEnableOption "obs-studio";
  };

  config = mkIf config.custom.obs-studio.enable {
    programs.obs-studio.enable = true;

    custom.persist = {
      home.directories = [ ".config/obs-studio" ];
    };
  };
}
