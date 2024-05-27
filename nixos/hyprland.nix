{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.hyprland.enable {
  services.xserver.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
  # services.xserver.displayManager.sddm.enable = lib.mkForce true;

  programs.hyprland =
    assert (
      lib.assertMsg (
        !(lib.hasPrefix pkgs.hyprland.version "0.40.0")
      ) "hyprland: updated, sync with hyprnstack?"
    );
    {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

  # set here as legacy linux won't be able to set these
  hm.wayland.windowManager.hyprland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
