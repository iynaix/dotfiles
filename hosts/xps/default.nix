_: {
  custom-nixos = {
    # impermanence
    persist = {
      tmpfs = false; # change to false to test zfs impermanence
      erase = true;
    };
  };

  networking.hostId = "abb4d116"; # required for zfs

  # touchpad support
  services.xserver.libinput.enable = true;
}
