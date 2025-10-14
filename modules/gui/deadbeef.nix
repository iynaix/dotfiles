{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.deadbeef.enable = mkEnableOption "deadbeef";
    };
  };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    mkIf config.custom.programs.deadbeef.enable {
      environment.systemPackages = [ pkgs.deadbeef ];

      custom.persist = {
        home.directories = [ ".config/deadbeef" ];
      };
    };
}
