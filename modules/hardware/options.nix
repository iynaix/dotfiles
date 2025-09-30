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
    hardware = {
      backlight.enable = mkEnableOption "Backlight" // {
        default = isLaptop;
      };
      battery.enable = mkEnableOption "Battery" // {
        default = isLaptop;
      };
      radeon.enable = mkEnableOption "AMD GPU" // {
        default = host == "framework";
      };
      wifi.enable = mkEnableOption "Wifi" // {
        default = isLaptop;
      };
      # dual boot windows
      mswindows = mkEnableOption "Dual Boot Windows" // {
        default = host == "desktop";
      };
    };
  };
}
