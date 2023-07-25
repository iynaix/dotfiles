{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.iynaix-nixos.hyprland;
in {
  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    # services.xserver.displayManager.sddm.enable = lib.mkForce true;

    # locking with swaylock
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    environment.systemPackages = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
}
