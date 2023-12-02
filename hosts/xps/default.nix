{user, ...}: {
  iynaix-nixos = {
    kanata.enable = true;
    zfs.encryption = true;

    # impermanence
    persist.tmpfs = true; # change to false to test zfs impermanence
    persist.erase.root = true;
    persist.erase.home = true;
  };

  networking.hostId = "abb4d116"; # required for zfs

  # allow building and pushing of laptop config from desktop
  nix.settings.trusted-users = [user];

  # touchpad support
  services.xserver.libinput.enable = true;
}
