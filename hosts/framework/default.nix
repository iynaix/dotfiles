_: {
  custom = {
    programs = {
      btop.settings = {
        custom_gpu_name0 = "AMD Radeon 780M";
      };
      freecad.enable = true;
      orca-slicer.enable = true;
      pathofbuilding.enable = true;
      rclip.enable = true;
      wallfacer.enable = true;
      waybar.hidden = true;
    };

    qmk.enable = true;
    virtualization.enable = true;
  };

  networking.hostId = "abb4d116"; # required for zfs

  hardware.framework.laptop13.audioEnhancement.enable = true;

  # touchpad support
  services.libinput.enable = true;

  # disable thumbprint reader
  services.fprintd.enable = false;
}
