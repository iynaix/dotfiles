{ lib, ... }:
{
  options.custom.persist = {
    home = {
      directories = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Files to persist in home directory";
      };
      cache = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Directories to persist, but not to snapshot";
      };
    };
  };
}
