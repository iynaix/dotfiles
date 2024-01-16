{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom-nixos.hyprland;
in {
  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    # services.xserver.displayManager.sddm.enable = lib.mkForce true;

    # locking with swaylock
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    programs.hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    # set here as legacy linux won't be able to set these
    hm.wayland.windowManager.hyprland = {
      enable = true;
      package = assert (lib.assertMsg (pkgs.hyprland.version == "0.34.0") "hyprland: updated, sync with hyprnstack?");
        pkgs.hyprland;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
