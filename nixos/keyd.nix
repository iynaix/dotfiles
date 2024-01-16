{
  config,
  lib,
  ...
}: let
  cfg = config.custom-nixos.keyd;
in {
  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;
      keyboards.true = {
        ids = ["*"];
        settings.main = {
          capslock = "overload(meta, esc)";
          rightshift = "C-s";
          rightalt = "C-c";
          rightcontrol = "C-v";
        };
      };
    };
  };
}
