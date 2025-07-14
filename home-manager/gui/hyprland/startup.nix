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
    autologinCommand = "uwsm start hyprland-uwsm.desktop";
  };

  wayland.windowManager.hyprland.settings = {
    exec-once =
      [
        # init ipc listener
        "hypr-ipc &"
        # stop fucking with my cursors
        "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
        "hyprctl dispatch workspace 1"
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
        if enable then "${rules} uwsm app -- ${exec}" else ""
      ) config.custom.startup;
  };

  # start swww and wallpaper via systemd to minimize reloads
  services.swww.enable = true;

  systemd.user.services = {
    wallpaper = {
      Install.WantedBy = [ "swww.service" ];
      Unit = {
        Description = "Set the wallpaper and update colorscheme";
        PartOf = [ config.wayland.systemd.target ];
        After = [ "swww.service" ];
        Requires = [ "swww.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart =
          let
            dotsExe = getExe' config.custom.dotfiles.package;
          in
          pkgs.writeShellScript "wallpaper-startup" ''
            ${dotsExe "wallpaper"}
            ${optionalString (config.custom.wm == "hyprland") dotsExe "hypr-monitors"}
          '';
        # possible race condition, introduce a small delay before starting
        # https://github.com/LGFae/swww/issues/317#issuecomment-2131282832
        ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 1";
      };
    };
  };
}
