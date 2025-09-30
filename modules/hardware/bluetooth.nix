{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe' mkEnableOption mkIf;
in
{
  options.custom = {
    hardware.bluetooth.enable = mkEnableOption "Bluetooth" // {
      default = isLaptop;
    };
  };

  config = mkIf config.custom.hardware.bluetooth.enable {
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
        ExecStart = getExe' pkgs.bluez "mpris-proxy";
      };
    };

    # add bluetooth audio icon to waybar
    custom.programs.waybar.config.pulseaudio = {
      format-bluetooth = "  {volume}%";
    };

    custom.persist = {
      root.directories = [ "/var/lib/bluetooth" ];
    };
  };
}
