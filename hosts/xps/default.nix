_: {
  custom = {
    # impermanence
    persist.tmpfs = false; # change to false to test zfs impermanence
  };

  networking.hostId = "abb4d116"; # required for zfs

  # touchpad support
  services.xserver.libinput.enable = true;
}
