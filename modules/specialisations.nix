{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.custom.specialisation;
in
# NOTE: specialisation options are defined in home-manager/default.nix
{
  options.custom = {
    specialisation = {
      current = mkOption {
        type = types.str;
        default = "";
        description = "The current specialisation being used";
      };

      hyprland.enable = mkEnableOption "hyprland specialisation";
      niri.enable = mkEnableOption "niri specialisation";
      mango.enable = mkEnableOption "mango specialisation";
    };
  };

  config = {
    environment.sessionVariables = {
      __SPECIALISATION = config.custom.specialisation.current;
    };

    specialisation = {
      # boot into a tty without a DE / WM
      tty = {
        configuration = {
          custom = {
            wm = "tty";
            specialisation.current = "tty";
          };
        };
      };

      # NOTE: no point having a separate boot option if that WM is already the default
      hyprland = mkIf (config.custom.wm != "hyprland" && cfg.hyprland.enable) {
        configuration = {
          custom = {
            wm = "hyprland";
            specialisation.current = "hyprland";
          };
        };
      };

      niri = mkIf (config.custom.wm != "niri" && cfg.niri.enable) {
        configuration = {
          custom = {
            wm = "niri";
            specialisation.current = "niri";
          };
        };
      };

      mango = mkIf (config.custom.wm != "mango" && cfg.mango.enable) {
        configuration = {
          custom = {
            wm = "mango";
            specialisation.current = "mango";
          };
        };
      };
    };
  };
}
