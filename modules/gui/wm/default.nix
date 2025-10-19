{
  flake.nixosModules.wm =
    { config, lib, ... }:
    lib.mkIf config.custom.isWm {
      environment = {
        sessionVariables = {
          DISPLAY = ":0";
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          # GDK_BACKEND = "wayland,x11,*";
        };
      };
    };
}
