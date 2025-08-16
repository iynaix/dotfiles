{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    getExe'
    mkIf
    optionalString
    ;
in
mkIf (config.custom.wm == "hyprland") {
  custom = {
    autologinCommand = "Hyprland";
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
      "hyprctl dispatch workspace 1"
      # disable middle click paste
      "${getExe' pkgs.wl-clipboard "wl-paste"} -p --watch ${getExe' pkgs.wl-clipboard "wl-copy"} -pc"
    ]
    # generate from startup options
    ++ map (
      {
        enable,
        spawn,
        workspace,
        ...
      }:
      let
        rules = optionalString (workspace != null) "[workspace ${toString workspace} silent]";
        exec = concatStringsSep " " spawn;
      in
      if enable then "${rules} ${exec}" else ""
    ) config.custom.startup;
  };

  systemd.user.services = {
    # listen to events from hyprland, done as a service so it will restart from nixos-rebuild
    hypr-ipc = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "Custom hypr-ipc from dotfiles-rs";
        After = [ "hyprland-session.target" ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = "${getExe' config.custom.dotfiles.package "hypr-ipc"}";
        Restart = "on-failure";
      };
    };
  };
}
