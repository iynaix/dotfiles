{
  config,
  host,
  lib,
  pkgs,
  user,
  ...
}:
let
  openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
in
lib.mkIf config.wayland.windowManager.hyprland.enable {
  # start hyprland
  custom.shell.profileExtra = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland &> /dev/null
    fi
  '';

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # init ipc listener
      "hypr-ipc &"

      "swww-daemon &"
      "sleep 1; hypr-wallpaper && launch-waybar"

      # fix gparted "cannot open display: :0" error
      "${lib.getExe pkgs.xorg.xhost} +local:${user}"
      # fix Authorization required, but no authorization protocol specified error
      # "${lib.getExe pkgs.xorg.xhost} si:localuser:root"

      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"

      # browsers
      (openOnWorkspace 1 "brave --incognito")
      (openOnWorkspace 1 "brave --profile-directory=Default")

      # file manager
      (openOnWorkspace 4 "nemo")

      # terminal
      (openOnWorkspace 7 "$term")

      # firefox
      (openOnWorkspace 9 (
        toString (
          [
            (lib.getExe config.programs.firefox.package)
            "-P"
            user # load user firefox profile
            "https://discordapp.com/channels/@me"
          ]
          ++ lib.optionals (host == "desktop") [
            "https://web.whatsapp.com" # requires access via local network
            "http://localhost:9091" # transmission
          ]
        )
      ))

      # download desktop
      (openOnWorkspace 10 "$term nvim ${config.xdg.userDirs.desktop}/yt.txt")
      (openOnWorkspace 10 "$term")

      # focus the initial workspaces on startup
      "hyprctl dispatch workspace 9"
      "hyprctl dispatch workspace 7"
      "hyprctl dispatch workspace 1"
    ];
  };
}
