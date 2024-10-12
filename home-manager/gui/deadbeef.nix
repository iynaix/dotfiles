{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    deadbeef.enable = mkEnableOption "deadbeef";
  };

  config = lib.mkIf config.custom.deadbeef.enable {
    home.packages = [ pkgs.deadbeef ];

    custom.persist = {
      home.directories = [ ".config/deadbeef" ];
    };
  };
}
