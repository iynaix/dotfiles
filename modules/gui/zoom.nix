{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom = {
    programs.zoom.enable = lib.mkEnableOption "Zoom";
  };

  config = lib.mkIf config.custom.programs.zoom.enable {
    environment.systemPackages = [ pkgs.zoom-us ];

    hm.xdg.configFile."zoomus.conf" = {
      text = ''
        [General]
        xwayland=false
        enableWaylandShare=true
      '';
    };
  };
}
