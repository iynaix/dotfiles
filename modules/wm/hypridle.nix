{
  config,
  lib,
  libCustom,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.custom) wm;
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
mkIf config.custom.isWm {
  # wrap the config into the hypridle executable
  custom.wrappers = [
    (
      { pkgs, ... }:
      {
        wrappers.hypridle = {
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
      }
    )
  ];

  services.hypridle.enable = true;

  # NOTE: screen lock on idle is handled in lock.nix
}
