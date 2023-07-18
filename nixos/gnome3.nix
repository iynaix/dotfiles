{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (!config.iynaix.hyprland.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
