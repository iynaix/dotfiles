{
  config,
  lib,
  pkgs,
  ...
}:
{
  # TODO: mostly copied from the hm-module.nix in the hypridle repo,
  # remove when there is an official hm module?
  xdg.configFile."hypr/hypridle.conf".text =
    let
      hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
    in
    ''
      general {
        lock_cmd = ${lib.optionalString config.custom.hyprland.lock "${config.xdg.cacheHome}/wallust/lock"}
        ignore_dbus_inhibit = false
      }

      listener {
        timeout = 500
        on-timeout = ${hyprctl} dispatch dpms off
        on-resume = ${hyprctl} dispatch dpms on
      }
    '';

  systemd.user.services.hypridle = {
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
