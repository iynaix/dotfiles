{
  config,
  lib,
  user,
  ...
}: {
  config = lib.mkIf (!config.home-manager.users.${user}.wayland.windowManager.hyprland.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
