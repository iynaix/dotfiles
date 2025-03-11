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
  systemd.user.services =
    let
      graphicalTarget = config.wayland.systemd.target;
    in
    {
      swww = {
        Install.WantedBy = [ graphicalTarget ];
        Unit = {
          Description = "Wayland wallpaper daemon";
          After = [ graphicalTarget ];
          PartOf = [ graphicalTarget ];
        };
        Service = {
          ExecStart = getExe' pkgs.swww "swww-daemon";
          Restart = "on-failure";
        };
      };
      wallpaper = {
        Install.WantedBy = [ "swww.service" ];
        Unit = {
          Description = "Set the wallpaper and update colorscheme";
          PartOf = [ graphicalTarget ];
          After = [ "swww.service" ];
          Requires = [ "swww.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = getExe' config.custom.dotfiles.package "wallpaper";
          # possible race condition, introduce a small delay before starting
          # https://github.com/LGFae/swww/issues/317#issuecomment-2131282832
          ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 1";
        };
      };
    };
}
