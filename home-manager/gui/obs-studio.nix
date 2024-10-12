{ config, lib, ... }:
{
  options.custom = with lib; {
    obs-studio.enable = mkEnableOption "obs-studio";
  };

  config = lib.mkIf config.custom.obs-studio.enable {
    programs.obs-studio.enable = true;

    custom.persist = {
      home.directories = [ ".config/obs-studio" ];
    };
  };
}
