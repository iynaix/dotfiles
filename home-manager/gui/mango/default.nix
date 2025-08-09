{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge;
in
mkMerge [
  {
    wayland.windowManager.mango = mkIf (config.custom.wm == "mango") {
      enable = true;
      systemd.enable = true;
      # settings = ''

      # '';
      # autostart_sh = ''

      # '';
    };
  }

  #TODO: remove when configured
  {
    custom.persist = {
      home.directories = [
        ".config/mango"
      ];
    };
  }
]
