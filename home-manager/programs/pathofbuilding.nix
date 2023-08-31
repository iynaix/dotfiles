{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.pathofbuilding;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.path-of-building];

    iynaix.persist = {
      home.directories = [
        ".local/share/pobfrontend"
      ];
    };
  };
}
