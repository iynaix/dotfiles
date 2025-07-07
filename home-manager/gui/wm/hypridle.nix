{ config, lib, ... }:
let
  inherit (lib) mkIf;
  dpmsOff =
    if config.custom.wm == "hyprland" then
      "hyprctl dispatch dpms off"
    else if config.custom.wm == "niri" then
      "niri msg action power-off-monitors"
    else
      "";
  dpmsOn =
    if config.custom.wm == "hyprland" then
      "hyprctl dispatch dpms on"
    else if config.custom.wm == "niri" then
      "niri msg action power-on-monitors"
    else
      "";
in
mkIf config.custom.isWm {
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
          on-timeout = dpmsOff;
          on-resume = dpmsOn;
        }
      ];
    };
  };
}
