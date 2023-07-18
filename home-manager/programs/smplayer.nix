{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.smplayer;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.smplayer];

    xdg.configFile."smplayer/themes" = {
      source = ./smplayer-themes;
      recursive = true;
    };

    iynaix.persist.home.directories = [
      ".config/smplayer"
    ];
  };
}
