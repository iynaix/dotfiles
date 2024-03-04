{ lib, ... }:
{
  options.custom-nixos.persist = {
    root = {
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist in root filesystem";
      };
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Files to persist in root filesystem";
      };
      cache = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist, but not to snapshot";
      };
    };
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
    };
    tmpfs = lib.mkEnableOption "tmpfs for for persist instead of snapshots" // {
      default = true;
    };
  };
}
