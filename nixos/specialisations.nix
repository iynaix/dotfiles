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
        hm.custom = {
          specialisation.current = "tty";
          wm = "tty";
        };
      };
    };

    # NOTE: no point having a separate boot option if WM is already the default
    hyprland = mkIf (config.hm.custom.wm != "hyprland" && cfg.hyprland.enable) {
      configuration = {
        hm.custom = {
          specialisation.current = "hyprland";
          wm = "hyprland";
        };
      };
    };

    niri = mkIf (config.hm.custom.wm != "niri" && cfg.niri.enable) {
      configuration = {
        hm.custom = {
          specialisation.current = "niri";
          wm = "niri";
        };
      };
    };

    mango = mkIf (config.hm.custom.wm != "mango" && cfg.mango.enable) {
      configuration = {
        hm.custom = {
          specialisation.current = "mango";
          wm = "mango";
        };
      };
    };
  };
}
