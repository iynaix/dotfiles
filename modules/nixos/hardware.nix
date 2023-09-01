{
  lib,
  config,
  ...
}: {
  options.iynaix-nixos = {
    am5.enable = lib.mkEnableOption "B650E-E motherboard";
    backlight.enable = lib.mkEnableOption "Backlight";
    nvidia.enable = lib.mkEnableOption "Nvidia GPU";
    wifi.enable = lib.mkEnableOption "Wifi";
    hdds = {
      enable = lib.mkEnableOption "Desktop HDDs";
      wdred6 = lib.mkEnableOption "WD Red 6TB" // {default = config.iynaix-nixos.hdds.enable;};
      ironwolf22 = lib.mkEnableOption "Ironwolf Pro 22TB" // {default = config.iynaix-nixos.hdds.enable;};
      windows = lib.mkEnableOption "Windows" // {default = config.iynaix-nixos.hdds.enable;};
      archlinux = lib.mkEnableOption "Arch Linux" // {default = config.iynaix-nixos.hdds.enable;};
    };

    zfs = {
      enable = lib.mkEnableOption "zfs" // {default = true;};
      swap = lib.mkEnableOption "swap";
      snapshots = lib.mkEnableOption "zfs snapshots" // {default = true;};
    };
  };
}
