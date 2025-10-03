{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    mkEnableOption
    mkIf
    optionalAttrs
    versionOlder
    ;
  # NOTE: nvidia.enable is a home-manager option so it can be referenced within home-manager as well
in
{
  options.custom = {
    hardware = {
      nvidia.enable = mkEnableOption "Nvidia GPU" // {
        default = host == "desktop";
      };
    };
  };

  config = mkIf config.custom.hardware.nvidia.enable {
    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" ];

    boot = {
      # nvidia-uvm is required for CUDA applications
      kernelModules = [ "nvidia-uvm" ];
      # use nvidia framebuffer
      # https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_module_parameters for more info.
      # kernelParams = [ "nvidia-drm.fbdev=1" ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = false;
        package =
          let
            betaPkg = config.boot.kernelPackages.nvidiaPackages.production;
          in
          assert (
            assertMsg (versionOlder betaPkg.version "580.95.06") "nvidia updated to ${betaPkg.version}, check orca-slicer"
          );
          betaPkg;
      };
      graphics.extraPackages = with pkgs; [
        vaapiVdpau
        # nvidia-vaapi-driver
        # libvdpau-va-gl
      ];
    };

    environment.variables = optionalAttrs config.custom.isWm {
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
