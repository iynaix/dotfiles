{
  isLaptop,
  lib,
  ...
}: {
  options.custom = {
    backlight.enable = lib.mkEnableOption "Backlight" // {default = isLaptop;};
    battery.enable = lib.mkEnableOption "Battery" // {default = isLaptop;};
    wifi.enable = lib.mkEnableOption "Wifi" // {default = isLaptop;};
  };
}
