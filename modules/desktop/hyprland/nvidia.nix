{ pkgs, host, user, lib, config, ... }:
{
  config = lib.mkIf (config.iynaix.hyprland.enable && host == "desktop") {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
    };

    home-manager.users.${user} = {
      wayland.windowManager.hyprland = {
        nvidiaPatches = true;
      };
    };
  };
}
