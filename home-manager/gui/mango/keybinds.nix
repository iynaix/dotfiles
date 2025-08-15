{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    getExe
    mkIf
    ;
  termExec = cmd: "${getExe config.custom.terminal.package} -e ${concatStringsSep " " cmd}";
  rofiExe = getExe config.programs.rofi.package;
in
mkIf (config.custom.wm == "mango") {
  custom.mango.settings = {
    bind = [
      "$mod, Return, spawn, ${getExe config.custom.terminal.package}"
      "$mod+SHIFT, Return, spawn ${rofiExe} -show drun"

      "$mod, BackSpace, killclient, "

      "$mod, e, spawn, nemo ${config.xdg.userDirs.download}"
      "$mod+Shift, e, spawn, ${
        termExec [
          "yazi"
          "${config.xdg.userDirs.download}"
        ]
      }"
      "$mod, w, spawn, ${getExe config.programs.chromium.package}"
      "$mod+Shift, w, spawn, ${getExe config.programs.chromium.package} --incognito"

      "$mod, v, spawn, ${termExec [ "nvim" ]}"
      "$mod+Shift, v, spawn, ${getExe pkgs.custom.shell.rofi-edit-proj}"

      # TODO: mango doesn't expose window title data, so focus-or-run cannot currently be implemented
      "$mod, period, spawn, codium ${config.home.homeDirectory}/projects/dotfiles"
      "$mod+SHIFT, period, spawn, codium ${config.home.homeDirectory}/projects/nixpkgs"

      # exit mango
      "ALT, F4, quit,"
      "CTRL+ALT, Delete, spawn, ${getExe config.custom.rofi-power-menu.package}"

      # clipboard history
      "$mod+CTRL, v, spawn, ${getExe pkgs.custom.shell.rofi-clipboard-history}"
    ]
    ++
      # workspace keybinds
      flatten (
        (lib.custom.mapWorkspaces (
          { workspace, key, ... }:
          [
            # Switch workspaces with $mod + [0-9]
            "$mod, ${key}, view, ${workspace}"
            # Move active window to a workspace with $mod + SHIFT + [0-9]
            "$mod+SHIFT, ${key}, tag, ${workspace}"
          ]
        ))
          config.custom.monitors
      );
  };
}
