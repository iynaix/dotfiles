{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    deadbeef.enable = mkEnableOption "deadbeef";
  };

  config = mkIf config.custom.deadbeef.enable {
    home.packages = [ pkgs.deadbeef ];

    custom.persist = {
      home.directories = [ ".config/deadbeef" ];
    };
  };
}
