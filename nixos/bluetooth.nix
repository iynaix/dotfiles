{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.bluetooth;
in {
  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    hm = {...} @ hmCfg: {
      # control media player over bluetooth
      services.mpris-proxy.enable = true;

      # add bluetooth audio icon to waybar
      iynaix.waybar.config.pulseaudio = lib.mkIf hmCfg.config.programs.waybar.enable {
        format-bluetooth = "  {volume}%";
      };
    };

    iynaix-nixos.persist = {
      root.directories = [
        "/var/lib/bluetooth"
      ];
    };
  };
}
