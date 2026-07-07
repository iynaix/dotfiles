{ lib, self, ... }:
{
  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        (writeShellApplication {
          name = "mango-focus-workspace";
          text = ''
            mmsg dispatch "focusmon,$1"
            mmsg dispatch "view,$2"
          '';
        })
        (writeShellApplication {
          name = "mango-move-to-workspace";
          text = ''
            mmsg dispatch "tagmon,$1"
            mmsg dispatch "tag,$2"
          '';
        })
      ];

      custom.programs.mango.settings = {
        bind =
          (
            # handle shared keybinds across WMs
            config.custom.wm.binds
            |> lib.mapAttrsToList (
              keys: args:
              let
                keyArr = keys |> lib.replaceString "Mod" "$mod" |> lib.splitString "+";
                mods = if (lib.length keyArr > 1) then lib.concatStringsSep "+" (lib.init keyArr) else "NONE";
              in
              "${mods}, ${lib.last keyArr}, spawn, ${args.spawn}"
            )
          )
          ++ [
            "$mod, BackSpace, killclient, "

            # TODO: mango doesn't expose window title data, so focus-or-run cannot currently be implemented

            # exit mango
            "ALT, F4, quit,"

            # fullscreen
            "$mod, f, togglefullscreen,"

            # sticky
            "$mod, g, togglefloating"

            # sticky
            "$mod, s, toggleglobal"

            # switch layout
            "$mod+SHIFT, n, switch_layout"

            "$mod, o, toggleoverview"
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
