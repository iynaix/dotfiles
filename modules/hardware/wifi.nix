{ lib, ... }:
{
  flake.modules.nixos.hardware_wifi = {
    custom.programs.noctalia.settings = {
      # add network shortcut as first item for control center
      control_center.shortcuts = [
        (lib.mkOrder 100 { type = "wifi"; })
      ];
    };

    custom.persist = {
      root.directories = [ "/etc/NetworkManager" ];
    };
  };
}
