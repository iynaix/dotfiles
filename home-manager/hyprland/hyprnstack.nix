{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}: let
  isHyprnstack = config.iynaix.hyprland.plugin == "hyprnstack";
in {
  wayland.windowManager.hyprland = lib.mkIf isHyprnstack {
    plugins = [inputs.hyprNStack.packages.${pkgs.system}.hyprNStack];

    settings.general.layout = lib.mkForce "nstack";

    # use hyprNStack plugin, the home-manager options do not seem to emit the plugin section
    extraConfig = ''
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
            mfact=0.0
          }
        }
      }
    '';
  };
}
