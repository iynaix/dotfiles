{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.vlc;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.vlc];

    iynaix.persist.home.directories = [".config/vlc"];
  };
}
