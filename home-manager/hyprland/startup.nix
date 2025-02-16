{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  openOnWorkspace =
    workspace: program: "[workspace ${toString workspace} silent] uwsm app -- ${program}";
in
lib.mkIf config.custom.hyprland.enable {
  custom.autologinCommand = "uwsm start hyprland-uwsm.desktop";

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
    exec-once = [
      # init ipc listener
      "hypr-ipc &"

      # fix gparted "cannot open display: :0" error
      "${lib.getExe pkgs.xorg.xhost} +local:${user}"
      # fix Authorization required, but no authorization protocol specified error
      # "${lib.getExe pkgs.xorg.xhost} si:localuser:root"

      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"

      # browsers
      "hyprctl dispatch workspace 1"
      (openOnWorkspace 1 "brave --incognito")
      (openOnWorkspace 1 "brave --profile-directory=Default")

      # file manager
      (openOnWorkspace 4 "nemo")

      # terminal
      (openOnWorkspace 7 "$term")

      # firefox
      (openOnWorkspace 9 (lib.getExe config.programs.firefox.package))

      # download desktop
      (openOnWorkspace 10 "$term nvim ${config.xdg.userDirs.desktop}/yt.txt")
      (openOnWorkspace 10 "$term")
    ];
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
          ExecStart = lib.getExe' pkgs.swww "swww-daemon";
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
          ExecStart = lib.getExe' config.custom.dotfiles.package "wallpaper";
          # possible race condition, introduce a small delay before starting
          # https://github.com/LGFae/swww/issues/317#issuecomment-2131282832
          ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 1";
        };
      };
    };
}
