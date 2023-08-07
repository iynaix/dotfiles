{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.hyprland;
  displays = config.iynaix.displays;
  openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
  hyprMonitors = pkgs.writeShellApplication {
    name = "hypr-monitors";
    text = ''
      hyprctl dispatch moveworkspacetomonitor 1 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 2 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 3 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 4 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 5 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 6 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 7 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 8 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 9 ${displays.monitor3}
      hyprctl dispatch moveworkspacetomonitor 10 ${displays.monitor3}

      hyprctl dispatch workspace 9
      hyprctl dispatch workspace 7
      hyprctl dispatch workspace 1

      hyprctl dispatch focusmonitor ${displays.monitor1}

      # set wallpapers again
      hypr-wallpaper --reload

      launch-waybar
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home.packages = [hyprMonitors];

    # start hyprland
    programs.zsh = let
      hyprlandInit = ''
        if [ "$(tty)" = "/dev/tty1" ]; then
          exec Hyprland &> /dev/null
        fi
      '';
    in {
      loginExtra = hyprlandInit;
      profileExtra = hyprlandInit;
    };

    xdg.configFile."hypr/ipc.py".source = ./ipc.py;

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        # init ipc listener
        "${pkgs.socat}/bin/socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | ${pkgs.python3}/bin/python ~/.config/hypr/ipc.py &"

        # browsers
        (openOnWorkspace 1 "brave --profile-directory=Default")
        (openOnWorkspace 1 "brave --incognito")

        # file manager
        (openOnWorkspace 4 "nemo")

        # terminal
        (openOnWorkspace 7 "$term")

        # firefox
        (openOnWorkspace 9 "firefox-devedition https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091")

        # download desktop
        (openOnWorkspace 10 "$term nvim ~/Desktop/yt.txt")
        (openOnWorkspace 10 "$term")

        "${pkgs.swayidle}/bin/swayidle -w timeout 480 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'"

        # focus the initial workspaces on startup
        "hyprctl dispatch workspace 9"
        "hyprctl dispatch workspace 7"
        "hyprctl dispatch workspace 1"

        # FIXME: weird race condition with swww init, need to sleep for a second
        # https://github.com/Horus645/swww/issues/144
        "sleep 1; swww init && hypr-wallpaper"
        "launch-waybar"

        # fix gparted "cannot open display: :0" error
        "${pkgs.xorg.xhost}/bin/xhost +local:"
        # fix Authorization required, but no authorization protocol specified error
        "${pkgs.xorg.xhost}/bin/xhost si:localuser:root"
      ];
    };
  };
}
