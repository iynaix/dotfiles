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
      lib.assertMsg (lib.versionOlder config.programs.hyprland.package.version "0.45") "hyprland updated, sync with hyprnstack?"
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
