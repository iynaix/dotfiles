{ lib, ... }:
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.zoom.enable = lib.mkEnableOption "Zoom";
    };

  };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    lib.mkIf config.custom.programs.zoom.enable {
      environment.systemPackages = [ pkgs.zoom-us ];

      hj.".config/zoomus.conf" = {
        text = ''
          [General]
          xwayland=false
          enableWaylandShare=true
        '';
      };
    };
}
