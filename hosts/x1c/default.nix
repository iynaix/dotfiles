_: {
  custom = {
    virtualization.enable = true;
    distrobox.enable = true;
  };

  networking.hostId = "ec7351ab"; # required for zfs

  # touchpad support
  services.libinput.enable = true;

  # disable thumbprint reader
  services.fprintd.enable = false;
}
