{
  pkgs,
  user,
  lib,
  ...
}: {
  imports = [./hardware.nix];

  config = {
    iynaix-nixos = {
      backlight.enable = true;
      hyprland.enable = true;
      zfs.swap = true;
      kmonad.enable = true;

      persist.root.directories = [
        "/etc/NetworkManager" # for wifi
      ];
    };

    networking.hostId = "abb4d116"; # required for zfs

    environment.systemPackages = with pkgs; [
      bc # needed for rofi-wifi-menu
      wirelesstools
    ];

    # touchpad support
    services.xserver.libinput.enable = true;

    # do not autologin on laptop!
    services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
    security.pam.services.gdm.enableGnomeKeyring = true;

    home-manager.users.${user} = {
      imports = [./home.nix];
    };
  };
}
