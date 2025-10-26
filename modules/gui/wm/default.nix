{
  flake.nixosModules.wm =
    { pkgs, ... }:
    {
      environment = {
        sessionVariables = {
          DISPLAY = ":0";
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          # GDK_BACKEND = "wayland,x11,*";
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
    };
}
