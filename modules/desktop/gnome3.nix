{
  config,
  lib,
  ...
}: {
  options.iynaix.gnome3 = {
    enable = lib.mkEnableOption "gnome3";
  };

  config = lib.mkIf (!config.iynaix.hyprland.enable) {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
