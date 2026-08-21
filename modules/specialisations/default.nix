{ config, lib, ... }:
{
  options.custom = {
    specialisation = {
      current = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The current specialisation being used";
      };
    };
  };

  config = {
    environment.sessionVariables = {
      __SPECIALISATION = config.custom.specialisation.current;
    };
  };
}
