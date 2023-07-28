{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (!config.iynaix-nixos.hyprland-nixos.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
