{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
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
      };
    };

  flake.nixosModules.specialisation-tty = {
    # boot into a tty without a DE / WM
    specialisation.tty = {
      configuration = {
        custom = {
          specialisation.current = "tty";
        };

        services.displayManager.ly.enable = lib.mkForce false;
      };
    };
  };

  flake.nixosModules.specialisation-hyprland = {
    specialisation.hyprland = {
      configuration = {
        custom = {
          specialisation.current = "hyprland";
        };

        services.displayManager.defaultSession = lib.mkForce "hyprland";
      };
    };
  };

  flake.nixosModules.specialisation-niri = {
    specialisation.niri = {
      configuration = {
        custom = {
          specialisation.current = "niri";
        };

        services.displayManager.defaultSession = lib.mkForce "niri";
      };
    };
  };

  flake.nixosModules.specialisation-mango = {
    specialisation.mango = {
      configuration = {
        custom = {
          specialisation.current = "mango";
        };

        services.displayManager.defaultSession = lib.mkForce "mango";
      };
    };
  };
}
