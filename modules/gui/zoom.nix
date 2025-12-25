{
  flake.nixosModules.zoom =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zoom-us ];

      hj.xdg.config.files."zoomus.conf" = {
        text = ''
          [General]
          xwayland=false
          enableWaylandShare=true
        '';
      };
    };
}
