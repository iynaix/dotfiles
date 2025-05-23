_: {
  custom = {
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
