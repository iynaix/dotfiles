{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.hm.custom.specialisation;
in
# NOTE: specialisation options are defined in home-manager/default.nix
{
  specialisation = {
    # boot into a tty without a DE / WM
    tty = {
      configuration = {
        custom.wm = "tty";
        hm.custom = {
          specialisation.current = "tty";
          wm = "tty";
        };
      };
    };

    # NOTE: no point having a separate boot option if that WM is already the default
    hyprland = mkIf (config.custom.wm != "hyprland" && cfg.hyprland.enable) {
      configuration = {
        custom.wm = "hyprland";
        hm.custom = {
          specialisation.current = "hyprland";
          wm = "hyprland";
        };
      };
    };

    niri = mkIf (config.custom.wm != "niri" && cfg.niri.enable) {
      configuration = {
        custom.wm = "niri";
        hm.custom = {
          specialisation.current = "niri";
          wm = "niri";
        };
      };
    };

    mango = mkIf (config.custom.wm != "mango" && cfg.mango.enable) {
      configuration = {
        custom.wm = "mango";
        hm.custom = {
          specialisation.current = "mango";
          wm = "mango";
        };
      };
    };
  };
}
