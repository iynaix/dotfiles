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
    };

    services.hypridle.enable = true;

    # by default, the service uses the systemd package from the hypridle derivation,
    # so using a config file is necessary
    hj.xdg.config.files."hypr/hypridle.conf".text = hypridleConfText;

    # NOTE: screen lock on idle is handled in lock.nix
  };
}
