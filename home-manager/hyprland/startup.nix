{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
in
lib.mkIf config.custom.hyprland.enable {
  custom.autologinCommand = lib.getExe config.wayland.windowManager.hyprland.package;

  # start hyprland
  programs.bash.profileExtra = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland &> /dev/null
    fi
  '';

  wayland.windowManager.hyprland.settings = {
    # HACK: Temporarily get waybar to launch.
    # exec = [
    #   "pgrep waybar || waybar &"
    # ];

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
  systemd.user.services = {
    swww = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        Description = "Wayland wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe' pkgs.swww "swww-daemon";
        Restart = "on-failure";
      };
    };
    wallpaper = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        Description = "Set the wallpaper and update colorscheme";
        PartOf = [ "graphical-session.target" ];
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
