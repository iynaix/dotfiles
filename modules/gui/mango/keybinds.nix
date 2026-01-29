{ lib, self, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      termExec = cmd: "ghostty -e ${lib.concatStringsSep " " cmd}";
    in
    {
      environment.systemPackages = with pkgs; [
        (writeShellApplication {
          name = "mango-focus-workspace";
          text = ''
            mmsg -d "focusmon,$1"
            mmsg -d "view,$2"
          '';
        })
        (writeShellApplication {
          name = "mango-move-to-workspace";
          text = ''
            mmsg -d "tagmon,$1"
            mmsg -d "tag,$2"
          '';
        })
      ];

      custom.programs.mango.settings = {
        bind = [
          "$mod, Return, spawn, ghostty"
          "$mod+SHIFT, Return, spawn, noctalia-ipc launcher toggle"

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
          "$mod+Shift, v, spawn, noctalia-ipc plugin:projects toggle"

          # TODO: mango doesn't expose window title data, so focus-or-run cannot currently be implemented
          "$mod, period, spawn, codium ${config.hj.directory}/projects/dotfiles"
          "$mod+SHIFT, period, spawn, codium ${config.hj.directory}/projects/nixpkgs"

          # exit mango
          "ALT, F4, quit,"
          "CTRL+ALT, Delete, spawn, noctalia-ipc sessionMenu toggle"

          # toggle the bar
          "$mod, a, spawn, noctalia-ipc bar toggle"

          # restart noctalia
          "$mod_SHIFT, a, spawn, noctalia-shell-reload"

          # clipboard history
          "$mod+CTRL, v, spawn, noctalia-ipc launcher clipboard"

          # notification history
          "$mod, n, exec, noctalia-ipc notifications toggleHistory"

          # fullscreen
          "$mod, f, togglefullscreen,"

          # sticky
          "$mod, g, togglefloating"

          # sticky
          "$mod, s, toggleglobal"

          # switch layout
          "$mod+SHIFT, n, switch_layout"

          "$mod, o, toggleoverview"

          # audio
          ",XF86AudioLowerVolume, spawn, pamixer -d 5"
          ",XF86AudioRaiseVolume, spawn, pamixer -i 5"
          ",XF86AudioMute, spawn, pamixer -t"
        ]
        ++
          # tag keybinds, switch to monitor first before switching tag
          lib.flatten (
            (self.libCustom.mapWorkspaces (
              {
                monitor,
                workspace,
                key,
                ...
              }:
              let
                # there are only 9 tags
                wksp = if workspace == "10" then "8" else workspace;
              in
              [
                # Switch workspaces with $mod + [0-9]
                "$mod, ${key}, spawn, mango-focus-workspace ${monitor.name} ${wksp}"
                # Move active window to a workspace with $mod + SHIFT + [0-9]
                "$mod+SHIFT, ${key}, spawn, mango-move-to-workspace ${monitor.name} ${wksp}"
              ]
            ))
              config.custom.hardware.monitors
          );
      };
    };
}
