{
  flake.modules.nixos.zoom =
    { pkgs, ... }:
    {
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
