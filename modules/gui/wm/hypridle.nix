{
  config,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    getExe
    mkIf
    versionOlder
    ;
  inherit (config.custom) wm;
  dpmsOff =
    if wm == "hyprland" then
      "hyprctl dispatch dpms off"
    else if wm == "niri" then
      "${getExe config.programs.niri.package} msg action power-off-monitors"
    else
      "";
  dpmsOn =
    if wm == "hyprland" then
      "hyprctl dispatch dpms on"
    else if wm == "niri" then
      "${getExe config.programs.niri.package} msg action power-on-monitors"
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

      # wrappers = [
      #   (_: _prev: {
      #     hypridle = {
      #       flags = {
      #         "--config" = pkgs.writeText "hypridle.conf" hypridleConfText;
      #       };
      #     };
      #   })
      # ];
    };

    services.hypridle.enable =
      assert (
        assertMsg (versionOlder pkgs.hypridle.version "0.1.8") "hypridle updated, use wrapper and custom service"
      );
      true;

    # by default, the service uses the systemd package from the hypridle derivation,
    # so using a config file is necessary
    hj.xdg.config.files."hypr/hypridle.conf".text = hypridleConfText;

    /*
      # don't use services.hyprland.enable as it uses the systemd service
      # from the derivation and is not overrideable
      systemd.user.services = {
        hypridle = {
          unitConfig = {
            Description = "Hyprland's idle daemon";
            Documentation = "https://wiki.hyprland.org/Hypr-Ecosystem/hypridle";
            PartOf = "graphical-session.target";
            After = "graphical-session.target";
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };

          serviceConfig = {
            Type = "simple";
            ExecStart = getExe pkgs.hypridle;
            Restart = "on-failure";
          };

          wantedBy = [ "graphical-session.target" ];
        };
      };
    */

    # NOTE: screen lock on idle is handled in lock.nix
  };
}
