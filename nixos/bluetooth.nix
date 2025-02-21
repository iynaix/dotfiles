{
  config,
  isLaptop,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    bluetooth.enable = mkEnableOption "Bluetooth" // {
      default = isLaptop;
    };
  };

  config = mkIf config.custom.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    hm = hmCfg: {
      # control media player over bluetooth
      services.mpris-proxy.enable = true;

      # add bluetooth audio icon to waybar
      custom.waybar.config.pulseaudio = mkIf hmCfg.config.programs.waybar.enable {
        format-bluetooth = "  {volume}%";
      };
    };

    custom.persist = {
      root.directories = [ "/var/lib/bluetooth" ];
    };
  };
}
