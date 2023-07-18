{
  lib,
  config,
  ...
}: {
  options.iynaix = {
    am5.enable = lib.mkEnableOption "B650E-E motherboard";
    backlight.enable = lib.mkEnableOption "Backlight";
    nvidia.enable = lib.mkEnableOption "Nvidia GPU";
    hdds.enable = lib.mkEnableOption "Desktop HDDs";

    displays = {
      monitor1 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The name of the primary display, e.g. eDP-1";
      };
      monitor2 = lib.mkOption {
        type = lib.types.str;
        default = config.iynaix.displays.monitor1;
        description = "The name of the secondary display, e.g. eDP-1";
      };
      monitor3 = lib.mkOption {
        type = lib.types.str;
        default = config.iynaix.displays.monitor1;
        description = "The name of the tertiary display, e.g. eDP-1";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "zfs" // {default = true;};
      swap = lib.mkEnableOption "swap";
      snapshots = lib.mkEnableOption "zfs snapshots" // {default = true;};
    };
  };
}
