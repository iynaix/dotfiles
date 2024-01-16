{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.vlc;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.vlc];

    custom.persist = {
      home.directories = [
        ".config/vlc"
      ];
    };
  };
}
