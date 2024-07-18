_: {
  custom = {
    vm.enable = true;
  };

  networking.hostId = "abb4d116"; # required for zfs

  # touchpad support
  services.libinput.enable = true;

  # disable thumbprint reader
  services.fprintd.enable = false;
}
