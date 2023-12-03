{user, ...}: {
  iynaix-nixos = {
    # TODO: enable with new config for device
    kanata.enable = false;
  };

  networking.hostId = "abb4d116"; # required for zfs

  # allow building and pushing of laptop config from desktop
  nix.settings.trusted-users = [user];

  # touchpad support
  services.xserver.libinput.enable = true;
}
