{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.obs-studio;
in {
  config = lib.mkIf cfg.enable {
    programs.obs-studio.enable = true;

    iynaix.persist = {
      home.directories = [
        ".config/obs-studio"
      ];
    };
  };
}
