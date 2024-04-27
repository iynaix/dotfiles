{ config, lib, ... }:
lib.mkIf (!config.hm.wayland.windowManager.hyprland.enable) {
  services = {
    # xserver.enable = true;
    # displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };
}
