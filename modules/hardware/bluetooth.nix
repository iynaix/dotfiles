{
  flake.nixosModules.bluetooth =
    { lib, pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      services.blueman.enable = true;

      # mpris user service to control media player over bluetooth,, implementation from home-manager:
      # https://github.com/nix-community/home-manager/blob/master/modules/services/mpris-proxy.nix
      systemd.user.services.mpris-proxy = {
        wantedBy = [ "bluetooth.target" ];

        unitConfig = {
          Description = "Proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players";
          BindsTo = [ "bluetooth.target" ];
          After = [ "bluetooth.target" ];
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = lib.getExe' pkgs.bluez "mpris-proxy";
        };
      };

      custom.persist = {
        root.directories = [ "/var/lib/bluetooth" ];
      };
    };
}
