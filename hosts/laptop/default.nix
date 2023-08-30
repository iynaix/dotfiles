{
  pkgs,
  lib,
  user,
  ...
}: {
  iynaix-nixos = {
    backlight.enable = true;
    hyprland-nixos.enable = true;
    zfs.swap = true;
    kmonad.enable = true;

    # impermanence
    persist.tmpfs = false;
    persist.erase.root = false;
    persist.erase.home = false;

    persist.root.directories = [
      "/etc/NetworkManager" # for wifi
    ];
  };

  networking.hostId = "abb4d116"; # required for zfs

  # allow building and pushing of laptop config from desktop
  nix.settings.trusted-users = [user];

  environment.systemPackages = with pkgs; [
    bc # needed for rofi-wifi-menu
    wirelesstools
  ];

  # touchpad support
  services.xserver.libinput.enable = true;

  # do not autologin on laptop!
  services.getty.autologinUser = lib.mkForce null;
  services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
  security.pam.services.gdm.enableGnomeKeyring = true;
}
