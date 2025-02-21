# hardware related options that are referenced within home-manager need to be defined here
# for home-manager to be able to access them
{
  host,
  isLaptop,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  options.custom = {
    backlight.enable = mkEnableOption "Backlight" // {
      default = isLaptop;
    };
    battery.enable = mkEnableOption "Battery" // {
      default = isLaptop;
    };
    wifi.enable = mkEnableOption "Wifi" // {
      default = isLaptop;
    };
    # dual boot windows
    mswindows = mkEnableOption "Windows" // {
      default = host == "desktop";
    };
  };
}
