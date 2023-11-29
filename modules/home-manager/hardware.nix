{lib, ...}: {
  options.iynaix = {
    backlight.enable = lib.mkEnableOption "Backlight";
    battery.enable = lib.mkEnableOption "Battery";
    wifi.enable = lib.mkEnableOption "Wifi";
  };
}
