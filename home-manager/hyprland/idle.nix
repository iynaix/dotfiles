{ config, lib, ... }:
{
  services.hypridle = {
    enable = true;

    settings =
      let
        timeout = 5 * 60;
      in
      lib.mkMerge [
        {
          general = {
            ignore_dbus_inhibit = false;
          };

          listener = [
            {
              inherit timeout;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        }
        # lock screen on idle
        (lib.mkIf config.custom.hyprland.lock {
          general = {
            lock_cmd = "hyprlock";
          };

          listener = [
            {
              inherit timeout;
              on-timeout = "hyprlock";
            }
          ];
        })
      ];
  };
}
