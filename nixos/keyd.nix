{
  config,
  lib,
  isLaptop,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    keyd.enable = mkEnableOption "keyd" // {
      default = isLaptop;
    };
  };

  config = mkIf config.custom.keyd.enable {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
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
