{ config, lib, ... }:
lib.mkIf config.custom.hyprland.enable {
  services.hypridle = {
    enable = true;

    # NOTE: screen lock on idle is handled in lock.nix
    settings = {
      general = {
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 5 * 60;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
