{
  config,
  lib,
  ...
}: let
  cfg = config.custom.obs-studio;
in {
  config = lib.mkIf cfg.enable {
    programs.obs-studio.enable = true;

    custom.persist = {
      home.directories = [
        ".config/obs-studio"
      ];
    };
  };
}
