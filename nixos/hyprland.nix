{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    mkIf
    optionalAttrs
    versionOlder
    ;
in
mkIf (config.hm.custom.wm == "hyprland") {
  programs.hyprland = {
    enable =
      assert (
        assertMsg (versionOlder config.programs.hyprland.package.version "0.51") "hyprland updated, sync with hyprnstack / hypr-darkwindow?"
      );
      true;
    inherit (config.hm.wayland.windowManager.hyprland) package;

    # needed for setting the wayland environment variables
    withUWSM = true;
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
  }
  // optionalAttrs (host == "vm" || host == "vm-hyprland") {
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
