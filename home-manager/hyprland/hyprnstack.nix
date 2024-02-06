{
  config,
  host,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = lib.mkIf (config.custom.hyprland.plugin == "hyprnstack") {
    plugins = [ pkgs.custom.hyprnstack ];

    settings.general.layout = "nstack";

    # use hyprNStack plugin, the home-manager options do not seem to emit the plugin section
    extraConfig = ''
      plugin {
        nstack {
          layout {
            orientation=left
            new_is_master=0
            stacks=${toString (if host == "desktop" then 3 else 2)}
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
