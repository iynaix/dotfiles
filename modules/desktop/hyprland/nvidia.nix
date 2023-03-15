{ pkgs, host, user, lib, config, ... }:
{
  config = lib.mkIf (config.iynaix.hyprland.enable && host == "desktop") {
    hardware.nvidia = {
      # open = true;
      modesetting.enable = true;
      # nvidiaPersistenced = true;
      # prevents crashes with nvidia on resuming, see:
      # https://github.com/hyprwm/Hyprland/issues/804#issuecomment-1369994379
      powerManagement.enable = false;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBVA_DRIVER_NAME = "nvidia";

      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    home-manager.users.${user} = {
      wayland.windowManager.hyprland = {
        nvidiaPatches = true;
      };
    };
  };
}
