{ config, lib, ... }:
lib.mkIf config.custom.keyd.enable {
  services.keyd = {
    enable = true;
    keyboards.true = {
      ids = [ "*" ];
      settings.main = {
        capslock = "overload(meta, esc)";
        rightshift = "C-s";
        rightalt = "C-c";
        rightcontrol = "C-v";
      };
    };
  };
}
