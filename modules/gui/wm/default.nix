{
  flake.nixosModules.wm =
    { pkgs, ... }:
    {
      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland";
        };
      };

      xdg.portal = {
        enable = true;
        config = {
          common.default = [ "gnome" ];
          obs.default = [ "gnome" ];
        };
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      hj.files.".face".source = ../../avatar.png;
    };
}
