{
  config,
  host,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.hm.custom.hyprland.enable {
  programs.hyprland.enable =
    assert (
      lib.assertMsg (lib.hasPrefix config.programs.hyprland.package.version "0.43.0") "hyprland: updated, sync with hyprnstack?"
    );
    true;

  environment.sessionVariables = lib.mkIf (host == "vm" || host == "vm-hyprland") {
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
