{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."hypr/hypridle.conf".text =
    let
      hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
      hyprlock = lib.getExe pkgs.hyprlock;
      timeout = toString (5 * 60);
    in
    ''
      general {
        lock_cmd = ${lib.optionalString config.custom.hyprland.lock hyprlock}
        ignore_dbus_inhibit = false
      }
      listener {
        timeout = ${timeout}
        on-timeout = ${hyprctl} dispatch dpms off
        on-resume = ${hyprctl} dispatch dpms on
      }
    ''
    # lock screen on idle
    + lib.optionalString config.custom.hyprland.lock ''
      listener {
        timeout = ${timeout}
        on-timeout = ${hyprlock}
      }
    '';

  systemd.user.services.hypridle =
    assert lib.assertMsg (!lib.hasAttr "hypridle" config.services) "hm now has a hypridle module";
    {
      Unit = {
        Description = "Hypridle";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe pkgs.hypridle;
        Restart = "always";
        RestartSec = "10";
      };

      Install.WantedBy = [ "default.target" ];
    };
}
