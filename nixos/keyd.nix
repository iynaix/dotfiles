{
  config,
  lib,
  isLaptop,
  ...
}:
{
  options.custom = with lib; {
    keyd.enable = mkEnableOption "keyd" // {
      default = isLaptop;
    };
  };

  config = lib.mkIf config.custom.keyd.enable {
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
