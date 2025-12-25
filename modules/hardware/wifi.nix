{
  flake.nixosModules.wifi =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.rofi-wifi-menu ];

      custom.persist = {
        root.directories = [ "/etc/NetworkManager" ];
      };
    };
}
