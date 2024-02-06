{ config, lib, ... }:
lib.mkIf config.custom.obs-studio.enable {
  programs.obs-studio.enable = true;

  custom.persist = {
    home.directories = [ ".config/obs-studio" ];
  };
}
