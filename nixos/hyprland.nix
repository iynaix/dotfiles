{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom-nixos.hyprland.enable {
  services.xserver.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
  # services.xserver.displayManager.sddm.enable = lib.mkForce true;

  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # set here as legacy linux won't be able to set these
  hm.wayland.windowManager.hyprland = {
    enable = true;
    package =
      assert (lib.assertMsg (pkgs.hyprland.version == "0.35.0")
        "hyprland: updated, sync with hyprnstack?"
      );
      pkgs.hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
