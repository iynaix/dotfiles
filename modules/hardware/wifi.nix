{ lib, ... }:
{
  flake.nixosModules.wifi = {
    custom.programs.noctalia.settingsReducers = [
      # enable wifi
      (prev: lib.recursiveUpdate prev { network.wifiEnabled = true; })
    ];

    custom.persist = {
      root.directories = [ "/etc/NetworkManager" ];
    };
  };
}
