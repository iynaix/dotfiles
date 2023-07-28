{
  config,
  lib,
  user,
  ...
}: let
  cfg = config.iynaix-nixos.nvidia;
in {
  config = lib.mkIf cfg.enable {
    # enable nvidia support
    services.xserver.videoDrivers = ["nvidia"];

    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    hardware.nvidia = {
      # open = true;
      modesetting.enable = true;
      # nvidiaPersistenced = true;
      # prevents crashes with nvidia on resuming, see:
      # https://github.com/hyprwm/Hyprland/issues/804#issuecomment-1369994379
      powerManagement.enable = false;
    };

    environment.sessionVariables = lib.mkIf config.iynaix-nixos.hyprland-nixos.enable {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBVA_DRIVER_NAME = "nvidia";

      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    home-manager.users.${user}.wayland.windowManager.hyprland.enableNvidiaPatches = config.iynaix-nixos.hyprland-nixos.enable;
  };
}
