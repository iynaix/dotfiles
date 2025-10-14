{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.vlc.enable = mkEnableOption "vlc";
    };
  };

  flake.modules.nixos.gui =
    {
      config,
      pkgs,
      ...
    }:
    mkIf config.custom.programs.vlc.enable {
      environment.systemPackages = [ pkgs.vlc ];

      custom.persist = {
        home.directories = [ ".config/vlc" ];
      };
    };
}
