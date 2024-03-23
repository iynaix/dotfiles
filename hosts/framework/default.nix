_: {
  custom-nixos = {
    vm.enable = true;
  };

  # by-id doesn't seem to work with amd mobo
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  networking.hostId = "abb4d116"; # required for zfs

  # touchpad support
  services.xserver.libinput.enable = true;

  # disable thumbprint reader
  services.fprintd.enable = false;
}
