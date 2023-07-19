{lib, ...}: {
  options.iynaix-nixos = {
    am5.enable = lib.mkEnableOption "B650E-E motherboard";
    backlight.enable = lib.mkEnableOption "Backlight";
    nvidia.enable = lib.mkEnableOption "Nvidia GPU";
    hdds.enable = lib.mkEnableOption "Desktop HDDs";

    zfs = {
      enable = lib.mkEnableOption "zfs" // {default = true;};
      swap = lib.mkEnableOption "swap";
      snapshots = lib.mkEnableOption "zfs snapshots" // {default = true;};
    };
  };
}
