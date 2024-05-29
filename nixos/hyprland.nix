{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.hm.custom.hyprland.enable {
  programs.hyprland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
