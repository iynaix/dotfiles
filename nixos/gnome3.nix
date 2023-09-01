{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (!config.iynaix-nixos.hyprland.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
