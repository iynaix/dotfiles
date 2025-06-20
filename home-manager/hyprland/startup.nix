{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    getExe
    getExe'
    mkAfter
    mkBefore
    mkMerge
    mkIf
    optionalString
    ;
in
mkIf config.custom.hyprland.enable {
  custom = {
    autologinCommand = "uwsm start hyprland-uwsm.desktop";
    startup = mkMerge [
      (mkBefore [
        # init ipc listener
        "hypr-ipc &"
        # stop fucking with my cursors
        "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
      ])
      (mkAfter [
        "hyprctl dispatch workspace 1"
      ])
    ];
  };

  # start hyprland
  programs.bash.profileExtra = # sh
    ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        if uwsm check may-start; then
          ${config.custom.autologinCommand}
        fi
      fi
    '';

  wayland.windowManager.hyprland.settings = {
    exec-once = map (
      prog:
      if builtins.isString prog then
        prog
      else
        let
          inherit (prog) exec packages workspace;
          rules = optionalString (workspace != null) "[workspace ${toString workspace} silent]";
          finalExec = if exec == null then concatMapStringsSep "\n" getExe packages else exec;
        in
        "${rules} uwsm app -- ${finalExec}"
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
            ${dotsExe "wm-monitors"}
          '';
        # possible race condition, introduce a small delay before starting
        # https://github.com/LGFae/swww/issues/317#issuecomment-2131282832
        ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 1";
      };
    };
  };
}
