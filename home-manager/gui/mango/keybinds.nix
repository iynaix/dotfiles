{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatLines
    concatStringsSep
    flatten
    getExe
    mkIf
    toUpper
    ;
  termExec = cmd: "${getExe config.custom.terminal.package} -e ${concatStringsSep " " cmd}";
  rofiExe = getExe config.programs.rofi.package;
  mod = "SUPER";
  mkBind =
    mods: key: action: args:
    "bind=${toUpper mods}, ${key}, ${action}, ${args}";
  mkSpawn =
    mods: key: cmd:
    mkBind mods key "spawn" "${cmd}";
in
mkIf (config.custom.wm == "mango") {
  wayland.windowManager.mango = {
    settings = concatLines (
      [
        (mkSpawn mod "Return" (getExe config.custom.terminal.package))
        (mkSpawn "${mod}+Shift" "Return" "${rofiExe} -show drun")

        (mkBind mod "BackSpace" "killclient" "")

        (mkSpawn "${mod}" "e" "nemo ${config.xdg.userDirs.download}")
        (mkSpawn "${mod}+Shift" "e"
          "${termExec [
            "yazi"
            "${config.xdg.userDirs.download}"
          ]}"
        )
        (mkSpawn mod "w" (getExe config.programs.chromium.package))
        (mkSpawn "${mod}+Shift" "w" "${getExe config.programs.chromium.package} --incognito")

        (mkSpawn mod "v" "${termExec [ "nvim" ]}")
        (mkSpawn "${mod}+Shift" "v" (getExe pkgs.custom.shell.rofi-edit-proj))

        # TODO: mango doesn't expose window title data, so focus-or-run cannot currently be implemented
        (mkSpawn mod "period" "codium ${config.home.homeDirectory}/projects/dotfiles")
        (mkSpawn "${mod}+Shift" "period" "codium ${config.home.homeDirectory}/projects/nixpkgs")

        # exit mango
        (mkBind "ALT" "F4" "quit" "")
        (mkSpawn "Ctrl+ALT" "Delete" (getExe config.custom.rofi-power-menu.package))

        # clipboard history
        (mkSpawn "${mod}+Ctrl" "v" (getExe pkgs.custom.shell.rofi-clipboard-history))
      ]
      ++
        # workspace keybinds
        flatten (
          (lib.custom.mapWorkspaces (
            { workspace, key, ... }:
            [
              # Switch workspaces with mainMod + [0-9]
              (mkBind mod key "view" workspace)
              # Move active window to a workspace with mainMod + SHIFT + [0-9]
              (mkBind "${mod}+Shift" key "tag" workspace)
            ]
          ))
            config.custom.monitors
        )
    );
  };
}
