{
  pkgs,
  lib,
  config,
  ...
}: let
  hypr-monitors = pkgs.writeShellScriptBin "hypr-monitors" ''
    ${pkgs.python3}/bin/python ${./hypr_monitors.py} --displays '${builtins.toJSON config.iynaix.displays}'
  '';
  nstackArg =
    if config.wayland.windowManager.hyprland.settings.general.layout == "nstack"
    then "--nstack"
    else "";
  hypr-ipc = pkgs.writeShellApplication {
    name = "hypr-ipc";
    runtimeInputs = with pkgs; [python3 socat];
    text = let
      ipcPath = "$HOME/projects/dotfiles/home-manager/hyprland/ipc.py";
    in ''
      socat - UNIX-CONNECT:"/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | python "${ipcPath}" ${nstackArg} "$@"
    '';
  };
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages = [hypr-monitors hypr-ipc];

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

        # init ipc listener
        ''${pkgs.socat}/bin/socat - UNIX-CONNECT:"/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | ${pkgs.python3}/bin/python ${./ipc.py} ${nstackArg} &''

        # fix gparted "cannot open display: :0" error
        "${pkgs.xorg.xhost}/bin/xhost +local:"
        # fix Authorization required, but no authorization protocol specified error
        "${pkgs.xorg.xhost}/bin/xhost si:localuser:root"
      ];
    };
  };
}
