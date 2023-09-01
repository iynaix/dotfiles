{
  config,
  host,
  pkgs,
  lib,
  ...
}: let
  hyprnstack = config.iynaix.hyprnstack;
in {
  config = {
    wayland.windowManager.hyprland = lib.mkIf hyprnstack {
      settings.general.layout = lib.mkForce "nstack";

      # use hyprNStack plugin, the home-manager options do not seem to emit the plugin section
      plugins = lib.mkIf hyprnstack [pkgs.iynaix.hyprNStack];
      extraConfig = lib.mkIf hyprnstack ''
        plugin {
          nstack {
            layout {
              orientation=left
              new_is_master=0
              stacks=${toString (
          if host == "desktop"
          then 3
          else 2
        )}
              # disable smart gaps
              no_gaps_when_only=0
              # master is the same size as the stacks
              mfact=0
            }
          }
        }
      '';
    };
  };
}
