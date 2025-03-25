{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom = {
    zoom.enable = lib.mkEnableOption "Zoom";
  };

  config = lib.mkIf config.custom.zoom.enable {
    home.packages = [ pkgs.zoom-us ];

    xdg.configFile."zoomus.conf" = {
      text = ''
        [General]
        xwayland=false
        enableWaylandShare=true
      '';
    };
  };
}
