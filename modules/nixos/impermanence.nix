{ config, lib, ... }:
{
  options.custom-nixos.persist = {
    root = {
      directories = lib.mkOption {
        default = [ ];
        description = "Directories to persist in root filesystem";
      };
      files = lib.mkOption {
        default = [ ];
        description = "Files to persist in root filesystem";
      };
      cache = lib.mkOption {
        default = [ ];
        description = "Directories to persist, but not to snapshot";
      };
    };
    home = {
      directories = lib.mkOption {
        default = [ ];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        default = [ ];
        description = "Files to persist in home directory";
      };
    };
    tmpfs = lib.mkEnableOption "tmpfs for for persist instead of snapshots" // {
      default = true;
    };
    erase = lib.mkOption {
      type = lib.types.bool;
      default = config.custom-nixos.persist.tmpfs;
      description = "Enable rollback to blank for / and /home";
    };
  };
}
