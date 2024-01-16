{
  config,
  lib,
  ...
}: let
  cfg = config.custom.helix;
in {
  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = {
        theme = "catppuccin_mocha";
      };
    };
  };
}
