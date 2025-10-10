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
    mkIf
    ;
  termExec = cmd: "ghostty -e ${concatStringsSep " " cmd}";
in
mkIf (config.custom.wm == "mango") {
  environment.systemPackages = with pkgs; [
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

  custom.programs.mango.settings = {
    bind = [
      "$mod, Return, spawn, ghostty"
      "$mod+SHIFT, Return, spawn, rofi -show drun"

      "$mod, BackSpace, killclient, "

      "$mod, e, spawn, nemo ${config.hj.directory}/Downloads"
      "$mod+Shift, e, spawn, ${
        termExec [
          "yazi"
          "${config.hj.directory}/Downloads"
        ]
      }"
      "$mod, w, spawn, helium"
      "$mod+Shift, w, spawn, helium --incognito"

      "$mod, v, spawn, ${termExec [ "nvim" ]}"
      "$mod+Shift, v, spawn, rofi-edit-proj"

      # TODO: mango doesn't expose window title data, so focus-or-run cannot currently be implemented
      "$mod, period, spawn, codium ${config.hj.directory}/projects/dotfiles"
      "$mod+SHIFT, period, spawn, codium ${config.hj.directory}/projects/nixpkgs"

      # exit mango
      "ALT, F4, quit,"
      "CTRL+ALT, Delete, spawn, rofi-power-menu"

      # clipboard history
      "$mod+CTRL, v, spawn, rofi-clipboard-history"
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
          config.custom.hardware.monitors
      );
  };
}
