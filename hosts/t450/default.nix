_: {
  custom = {
    virtualization.enable = true;
  };

  networking.hostId = "a8637ae8"; # required for zfs

  # larger runtime directory size to not run out of ram while building
  # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
  services.logind.extraConfig = "RuntimeDirectorySize=3G";

  # touchpad support
  services.libinput.enable = true;
}
