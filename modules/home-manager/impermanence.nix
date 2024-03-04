{ lib, ... }:
{
  options.custom.persist = {
    home = {
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Files to persist in home directory";
      };
      cache = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist, but not to snapshot";
      };
    };
  };
}
