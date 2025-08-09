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
    getExe
    toUpper
    ;
  termExec = cmd: "${getExe config.custom.terminal.package} -e ${concatStringsSep " " cmd}";
  rofiExe = getExe config.programs.rofi.package;
  mod = "SUPER";
  mkBind =
    mods: key: action: args:
    "bind=${toUpper mods},${key},${action},${args}";
  mkSpawn =
    mods: key: cmd:
    mkBind mods key "spawn" "${cmd}";
in
{
  custom.mango = {
    # TODO: focus-or-run

    settings = concatLines [
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

      # (mkSpawn mod "period"
      #   ''focus-or-run "dotfiles - VSCodium" "codium ${config.home.homeDirectory}/projects/dotfiles"''
      # )
      # (mkSpawn "${mod}+Shift" "period"
      #   ''focus-or-run "nixpkgs - VSCodium" "codium ${config.home.homeDirectory}/projects/nixpkgs"''
      # )

      # exit mango
      (mkBind "ALT" "F4" "quit" "")
      (mkSpawn "Ctrl+ALT" "Delete" (getExe config.custom.rofi-power-menu.package))

      # clipboard history
      (mkSpawn "${mod}+Ctrl" "v" (getExe pkgs.custom.shell.rofi-clipboard-history))
    ];
  };
}
