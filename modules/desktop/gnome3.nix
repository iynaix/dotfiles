{ config, lib, ... }:
{
  config = lib.mkIf (!config.iynaix.bspwm) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
