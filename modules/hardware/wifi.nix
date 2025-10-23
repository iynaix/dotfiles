{ lib, ... }:
{
  flake.nixosModules.wifi =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.rofi-wifi-menu ];

      custom.programs = {
        waybar.config = {
          network = {
            format = "    {essid}";
            format-ethernet = lib.mkForce " ";
            # rofi wifi script
            on-click = lib.getExe pkgs.custom.rofi-wifi-menu;
            on-click-right = "ghostty -e nmtui";
          };
        };

      };

      custom.persist = {
        root.directories = [ "/etc/NetworkManager" ];
      };
    };
}
