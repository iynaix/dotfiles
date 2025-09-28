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
  hypridleConfText = libCustom.toHyprconf {
    attrs = config.custom.programs.hypridle.settings;
    importantPrefixes = [ "$" ];
  };
in
{
  options.custom = {
    programs.hypridle = {
      settings = libCustom.types.hyprlandSettingsType;
    };
  };

  config = mkIf config.custom.isWm {
    custom = {
      programs.hypridle.settings = {
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

      # wrap the config into the hypridle executable
      wrappers = [
        (
          { pkgs, ... }:
          {
            wrappers.hypridle = {
              basePackage = pkgs.hypridle;
              prependFlags = [
                "--config"
                (pkgs.writeText "hypridle.conf" hypridleConfText)
              ];
            };
          }
        )
      ];
    };

    services.hypridle.enable = true;

    # NOTE: screen lock on idle is handled in lock.nix
  };
}
