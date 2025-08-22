{
  config,
  inputs,
  lib,
  libCustom,
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
  home.packages = with pkgs; [
    (writeShellApplication {
      name = "mango-focus-workspace";
      runtimeInputs = [ inputs.mango.packages.${pkgs.system}.mmsg ];
      text = ''
        mmsg -d "focusmon,$1"
        mmsg -d "view,$2"
      '';
    })
    (writeShellApplication {
      name = "mango-move-to-workspace";
      runtimeInputs = [ inputs.mango.packages.${pkgs.system}.mmsg ];
      text = ''
        mmsg -d "tagmon,$1"
        mmsg -d "tag,$2"
      '';
    })
  ];

  custom.mango.settings = {
    bind = [
      "$mod, Return, spawn, ${getExe config.custom.terminal.package}"
      "$mod+SHIFT, Return, spawn, ${rofiExe} -show drun"

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
      # tag keybinds, switch to monitor first before switching tag
      flatten (
        (libCustom.mapWorkspaces (
          {
            monitor,
            workspace,
            key,
            ...
          }:
          [
            # Switch workspaces with $mod + [0-9]
            ''$mod, ${key}, spawn, mango-focus-workspace ${monitor.name} ${workspace}''
            # Move active window to a workspace with $mod + SHIFT + [0-9]
            ''$mod+SHIFT, ${key}, spawn, mango-move-to-workspace ${monitor.name} ${workspace}''
          ]
        ))
          config.custom.monitors
      );
  };
}
