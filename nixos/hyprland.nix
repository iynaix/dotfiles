{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.hyprland.enable {
  services.xserver.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
  # services.xserver.displayManager.sddm.enable = lib.mkForce true;

  programs.hyprland =
    #   assert (
    #     lib.assertMsg (pkgs.hyprland.version == "0.39.1") "hyprland: updated, sync with hyprnstack?"
    #   );
    {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

  # set here as legacy linux won't be able to set these
  hm.wayland.windowManager.hyprland.enable = true;

  # lock hyprland to 0.38.1 until workspace switching is resolved
  nixpkgs.overlays = [ (_: _prev: { inherit (inputs.hyprland.packages.${pkgs.system}) hyprland; }) ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
