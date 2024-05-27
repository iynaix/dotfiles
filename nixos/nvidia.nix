{
  config,
  host,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.nvidia.enable {
  # enable nvidia support
  services.xserver.videoDrivers = [ "nvidia" ];

  boot = {
    # use nvidia framebuffer
    # https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_module_parameters for more info.
    kernelParams = [ "nvidia-drm.fbdev=1" ];
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
    opengl.extraPackages = [ pkgs.vaapiVdpau ];
  };

  environment = {
    sessionVariables =
      {
        NIXOS_OZONE_WL = "1";
      }
      // lib.optionalAttrs config.programs.hyprland.enable (
        {
          LIBVA_DRIVER_NAME = "nvidia";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        }
        // lib.optionalAttrs (host == "vm" || host == "vm-amd") { WLR_RENDERER_ALLOW_SOFTWARE = "1"; }
      );
  };

  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
