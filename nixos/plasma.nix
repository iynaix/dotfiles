{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (!config.hm.wayland.windowManager.hyprland.enable) {
    services.xserver = {
      enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
