{ user, ... }:
{
  custom-nixos = {
    # impermanence
    persist = {
      tmpfs = false; # change to false to test zfs impermanence
      erase.root = true;
      erase.home = true;
    };
  };

  networking.hostId = "abb4d116"; # required for zfs

  # allow building and pushing of laptop config from desktop
  nix.settings.trusted-users = [ user ];

  # touchpad support
  services.xserver.libinput.enable = true;
}
