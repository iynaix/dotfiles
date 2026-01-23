{
  flake.nixosModules.core =
    { config, lib, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkForce
        mkIf
        mkOption
        ;
      cfg = config.custom.specialisation;
    in
    # NOTE: specialisation options are defined in home-manager/default.nix
    {
      options.custom = {
        specialisation = {
          current = mkOption {
            type = lib.types.str;
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
                specialisation.current = "tty";
              };

              services.displayManager.ly.enable = mkForce false;
            };
          };

          hyprland = mkIf cfg.hyprland.enable {
            configuration = {
              custom = {
                specialisation.current = "hyprland";
              };

              services.displayManager.defaultSession = mkForce "hyprland";
            };
          };

          niri = mkIf cfg.niri.enable {
            configuration = {
              custom = {
                specialisation.current = "niri";
              };

              services.displayManager.defaultSession = mkForce "niri";
            };
          };

          mango = mkIf cfg.mango.enable {
            configuration = {
              custom = {
                specialisation.current = "mango";
              };

              services.displayManager.defaultSession = mkForce "mango";
            };
          };
        };
      };
    };
}
