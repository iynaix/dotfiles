{ lib, ... }:
{
  flake.nixosModules.core = {
    options.custom = {
      constants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };
    };
  };
}
