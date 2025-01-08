{
  config,
  host,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.hm.custom.hyprland.enable {
  programs.hyprland = {
    enable =
      assert (
        lib.assertMsg (lib.versionOlder config.programs.hyprland.package.version "0.47") "hyprland updated, sync with hyprnstack?"
      );
      true;

    # needed for setting the wayland environment variables
    withUWSM = true;
  };

  environment.variables =
    {
      NIXOS_OZONE_WL = "1";
    }
    // lib.optionalAttrs (host == "vm" || host == "vm-hyprland") {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
    };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
