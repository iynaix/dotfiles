{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.hm.custom.hyprland.enable {
  programs.hyprland.enable =
    assert (
      lib.assertMsg (lib.hasPrefix config.programs.hyprland.package.version "0.41.1") "hyprland: updated, sync with hyprnstack?"
    );
    true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
