{ config, lib, ... }:
{
  config = lib.mkIf (!config.iynaix.bspwm.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
