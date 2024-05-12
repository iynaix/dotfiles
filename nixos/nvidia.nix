{
  config,
  host,
  lib,
  ...
}:
lib.mkIf config.custom.nvidia.enable {
  # enable nvidia support
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
  };

  environment = {
    sessionVariables =
      {
        NIXOS_OZONE_WL = "1";
      }
      // lib.optionalAttrs config.programs.hyprland.enable (
        {
          WLR_NO_HARDWARE_CURSORS = "1";
          LIBVA_DRIVER_NAME = "nvidia";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        }
        // lib.optionalAttrs (host == "vm" || host == "vm-amd") { WLR_RENDERER_ALLOW_SOFTWARE = "1"; }
      );
  };
}
