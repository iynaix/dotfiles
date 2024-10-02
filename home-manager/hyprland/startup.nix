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
lib.mkIf config.custom.hyprland.enable {
  # start hyprland
  programs.bash.profileExtra = ''
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

      # lock screen to protect privacy
      "hyprlock"

      # fix gparted "cannot open display: :0" error
      "${lib.getExe pkgs.xorg.xhost} +local:${user}"
      # fix Authorization required, but no authorization protocol specified error
      # "${lib.getExe pkgs.xorg.xhost} si:localuser:root"

      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"

      # terminal
      (openOnWorkspace 1 "$term")

      # firefox
      (openOnWorkspace 5 (
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
      (openOnWorkspace 10 "$term hx ${config.xdg.userDirs.desktop}/yt.txt")
      (openOnWorkspace 10 "$term")

      # focus the initial workspaces on startup
      "hyprctl dispatch workspace 10"
      "hyprctl dispatch workspace 5"
      "hyprctl dispatch workspace 1"
    ];
  };
}
