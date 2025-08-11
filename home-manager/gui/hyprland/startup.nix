{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    getExe'
    mkIf
    optionalString
    ;
in
mkIf (config.custom.wm == "hyprland") {
  custom = {
    autologinCommand = "Hyprland";
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # init ipc listener
      "hypr-ipc &"
      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
      "hyprctl dispatch workspace 1"
      # disable middle click paste
      "${getExe' pkgs.wl-clipboard "wl-paste"} -p --watch ${getExe' pkgs.wl-clipboard "wl-copy"} -pc"
    ]
    # generate from startup options
    ++ map (
      {
        enable,
        spawn,
        workspace,
        ...
      }:
      let
        rules = optionalString (workspace != null) "[workspace ${toString workspace} silent]";
        exec = concatStringsSep " " spawn;
      in
      if enable then "${rules} ${exec}" else ""
    ) config.custom.startup;
  };
}
