{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    nvidia.enable = mkEnableOption "Nvidia GPU";
  };

  config = lib.mkIf config.custom.nvidia.enable {
    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" ];

    boot = {
      # nvidia-uvm is required for CUDA applications
      kernelModules = [ "nvidia-uvm" ];
      # use nvidia framebuffer
      # https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_module_parameters for more info.
      kernelParams = [ "nvidia-drm.fbdev=1" ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = false;
        package =
          let
            betaPkg = config.boot.kernelPackages.nvidiaPackages.beta;
          in
          assert (
            lib.assertMsg (lib.versionOlder betaPkg.version "570.87") "nvidia updated, check slicers / freecad"
          );
          betaPkg;
      };
      graphics.extraPackages = with pkgs; [
        vaapiVdpau
        # nvidia-vaapi-driver
        # libvdpau-va-gl
      ];
    };

    environment.variables = lib.optionalAttrs config.programs.hyprland.enable {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    nix.settings = {
      substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}
