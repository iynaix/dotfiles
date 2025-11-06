{
  flake.nixosModules.host-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
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
              lib.assertMsg (lib.versionOlder betaPkg.version "580.95.06") "nvidia updated to ${betaPkg.version}, check orca-slicer"
            );
            betaPkg;
        };
        graphics.extraPackages = with pkgs; [
          libva-vdpau-driver
          # nvidia-vaapi-driver
          # libvdpau-va-gl
        ];
      };

      environment.variables = {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      # nvidia specific settings for hyprland
      custom.programs.hyprland.settings = {
        cursor = {
          # no_hardware_cursors = true;
          use_cpu_buffer = 1;
        };
      };
    };
}
