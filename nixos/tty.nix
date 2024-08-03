{ lib, ... }:
{
  specialisation = {
    # boot into a tty without a DE / WM
    tty.configuration = {
      hm.custom.hyprland.enable = lib.mkForce false;

      services = {
        xserver = {
          enable = lib.mkForce false;
          desktopManager.plasma5.enable = lib.mkForce false;
        };
        desktopManager.plasma6.enable = lib.mkForce false;
      };
    };
  };
}
