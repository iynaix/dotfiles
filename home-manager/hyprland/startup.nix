{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    # start hyprland
    iynaix.shell.profileExtra = lib.mkIf config.iynaix.hyprland.autostart ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland &> /dev/null
      fi
    '';

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        # init ipc listener
        "hypr-ipc &"

        # browsers
        (openOnWorkspace 1 "brave --incognito")
        (openOnWorkspace 1 "brave --profile-directory=Default")

        # file manager
        (openOnWorkspace 4 "nemo")

        # terminal
        (openOnWorkspace 7 "$term")

        # firefox
        (openOnWorkspace 9 "firefox-developer-edition https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091")

        # download desktop
        (openOnWorkspace 10 "$term nvim ~/Desktop/yt.txt")
        (openOnWorkspace 10 "$term")

        "${lib.getExe pkgs.swayidle} -w timeout 480 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'"

        # focus the initial workspaces on startup
        "hyprctl dispatch workspace 9"
        "hyprctl dispatch workspace 7"
        "hyprctl dispatch workspace 1"

        # FIXME: weird race condition with swww init, need to sleep for a second
        # https://github.com/Horus645/swww/issues/144
        "sleep 1; swww init && hypr-wallpaper"

        "sleep 5 && launch-waybar"

        # fix gparted "cannot open display: :0" error
        "${lib.getExe pkgs.xorg.xhost} +local:${user}"
        # fix Authorization required, but no authorization protocol specified error
        # "${lib.getExe pkgs.xorg.xhost} si:localuser:root"

        # start the polkit agent
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &"
      ];
    };
  };
}
