{ config, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) enum bool;
in
{
  options.custom = {
    wm = mkOption {
      description = "The WM to use, either hyprland / niri / mango / plasma / tty";
      type = enum [
        "hyprland"
        "niri"
        "mango"
        "plasma"
        "tty"
      ];
      default = "hyprland";
    };

    isWm = mkOption {
      description = "Readonly option to check if the WM is hyprland / niri / mango";
      type = bool;
      default =
        config.custom.wm == "hyprland" || config.custom.wm == "niri" || config.custom.wm == "mango";
      readOnly = true;
    };
  };
}
