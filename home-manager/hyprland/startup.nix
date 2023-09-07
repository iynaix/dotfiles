{
  pkgs,
  lib,
  config,
  ...
}: let
  hyprMonitors = pkgs.writeShellApplication {
    name = "hypr-monitors";
    text = let
      displays = config.iynaix.displays;
      resetWorkspaces = lib.concatStringsSep "\n" (lib.concatMap ({
        name,
        workspaces,
        ...
      }:
        lib.forEach workspaces (ws: "hyprctl dispatch moveworkspacetomonitor ${toString ws} ${name}"))
      displays);
    in ''
      ${resetWorkspaces}

      hyprctl dispatch workspace 9
      hyprctl dispatch workspace 7
      hyprctl dispatch workspace 1

      hyprctl dispatch focusmonitor ${(builtins.head displays).name}

      # set wallpapers again
      hypr-wallpaper --reload

      launch-waybar
    '';
  };
  hyprIpc = pkgs.writeShellApplication {
    name = "hypr-ipc";
    runtimeInputs = with pkgs; [python3 socat];
    text = let
      nstackArg =
        if config.wayland.windowManager.hyprland.settings.general.layout == "nstack"
        then "--nstack"
        else "";
    in ''
      socat - UNIX-CONNECT:"/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | python ${./ipc.py} ${nstackArg} "$@"
    '';
  };
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages = [hyprMonitors hyprIpc];

    # start hyprland
    iynaix.shell.profileExtra = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland &> /dev/null
      fi
    '';

    wayland.windowManager.hyprland.settings = {
      exec-once = let
        openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
      in [
        # init ipc listener
        "${hyprIpc}/bin/hypr-ipc -nstack &"

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
