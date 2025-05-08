{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    mkIf
    optionalAttrs
    versionOlder
    ;
in
# NOTE: nvidia.enable is a home-manager option so it can be referenced within home-manager as well
mkIf config.hm.custom.nvidia.enable {
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
          betaPkg = config.boot.kernelPackages.nvidiaPackages.beta;
        in
        assert (assertMsg (versionOlder betaPkg.version "575.51.03") "nvidia updated, check orca-slicer");
        betaPkg;
    };
    graphics.extraPackages = with pkgs; [
      vaapiVdpau
      # nvidia-vaapi-driver
      # libvdpau-va-gl
    ];
  };

  environment.variables = optionalAttrs config.programs.hyprland.enable {
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
}
