{
  config,
  host,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom-nixos.nvidia.enable {
  # enable nvidia support
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
  };

  environment = {
    systemPackages = [ pkgs.nvtop ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    } // lib.optionalAttrs (host == "vm" || host == "vm-amd") { WLR_RENDERER_ALLOW_SOFTWARE = "1"; };
  };
}
