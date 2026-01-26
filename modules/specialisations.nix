{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
    let
      cfg = config.custom.specialisation;
    in
    # NOTE: specialisation options are defined in home-manager/default.nix
    {
      options.custom = {
        specialisation = {
          current = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "The current specialisation being used";
          };

          hyprland.enable = lib.mkEnableOption "hyprland specialisation";
          niri.enable = lib.mkEnableOption "niri specialisation";
          mango.enable = lib.mkEnableOption "mango specialisation";
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
                specialisation.current = "tty";
              };

              services.displayManager.ly.enable = lib.mkForce false;
            };
          };

          hyprland = lib.mkIf cfg.hyprland.enable {
            configuration = {
              custom = {
                specialisation.current = "hyprland";
              };

              services.displayManager.defaultSession = lib.mkForce "hyprland";
            };
          };

          niri = lib.mkIf cfg.niri.enable {
            configuration = {
              custom = {
                specialisation.current = "niri";
              };

              services.displayManager.defaultSession = lib.mkForce "niri";
            };
          };

          mango = lib.mkIf cfg.mango.enable {
            configuration = {
              custom = {
                specialisation.current = "mango";
              };

              services.displayManager.defaultSession = lib.mkForce "mango";
            };
          };
        };
      };
    };
}
