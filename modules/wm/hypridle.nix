{
  config,
  inputs,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.hm.custom) wm;
  dpmsOff =
    if wm == "hyprland" then
      "hyprctl dispatch dpms off"
    else if wm == "niri" then
      "niri msg action power-off-monitors"
    else
      "";
  dpmsOn =
    if wm == "hyprland" then
      "hyprctl dispatch dpms on"
    else if wm == "niri" then
      "niri msg action power-on-monitors"
    else
      "";
  hypridleConf = {
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
in
mkIf config.hm.custom.isWm {
  services.hypridle = {
    enable = true;

    package = inputs.wrapper-manager.lib.wrapWith pkgs {
      basePackage = pkgs.hypridle;
      prependFlags = [
        "--config"
        (pkgs.writeText "hypridle.conf" (
          libCustom.toHyprconf {
            attrs = hypridleConf;
            importantPrefixes = [ "$" ];
          }
        ))
      ];
    };

    # NOTE: screen lock on idle is handled in lock.nix
  };
}
