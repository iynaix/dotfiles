{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.deadbeef;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.deadbeef];

    iynaix.persist = {
      home.directories = [
        ".config/deadbeef"
      ];
    };
  };
}
