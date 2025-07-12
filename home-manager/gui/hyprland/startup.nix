{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib)
    getExe
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
      let
        braveExe = getExe config.programs.chromium.package;
      in
      [
        # init ipc listener
        "hypr-ipc &"

        # browsers
        "[workspace 1 silent] uwsm app -- ${braveExe} --incognito"
        "[workspace 1 silent] uwsm app -- ${braveExe} --profile-directory=Default"
        # file manager
        "[workspace 4 silent] uwsm app -- nemo"
        # terminal
        "[workspace 7 silent] uwsm app -- ${getExe config.custom.terminal.package}"

        # librewolf for discord
        "[workspace 9 silent] uwsm app -- ${getExe config.programs.librewolf.package}"

        # download related
        "[workspace 10 silent] uwsm app -- ${config.custom.terminal.exec} nvim ${config.xdg.userDirs.desktop}/yt.txt"
        "[workspace 10 silent] uwsm app -- ${getExe config.custom.terminal.package}"

        # misc
        # fix gparted "cannot open display: :0" error
        "uwsm app -- ${getExe pkgs.xorg.xhost} +local:${user}"
        # fix Authorization required, but no authorization protocol specified error
        "uwsm app -- ${getExe pkgs.xorg.xhost} si:localuser:root"

        # stop fucking with my cursors
        "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
        "hyprctl dispatch workspace 1"

      ];
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
