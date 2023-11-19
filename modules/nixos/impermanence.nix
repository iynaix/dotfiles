{
  config,
  lib,
  ...
}: {
  options.iynaix-nixos.persist = {
    root = {
      directories = lib.mkOption {
        default = [];
        description = "Directories to persist in root filesystem";
      };
      files = lib.mkOption {
        default = [];
        description = "Files to persist in root filesystem";
      };
    };
    home = {
      directories = lib.mkOption {
        default = [];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        default = [];
        description = "Files to persist in home directory";
      };
    };
    tmpfs = lib.mkEnableOption "Enable tmpfs for for persist instead of snapshots" // {default = true;};
    erase = {
      root = lib.mkOption {
        type = lib.types.bool;
        default = config.iynaix-nixos.persist.tmpfs;
        description = "Enable rollback to blank for /";
      };
      home = lib.mkOption {
        type = lib.types.bool;
        default = config.iynaix-nixos.persist.tmpfs;
        description = "Enable rollback to blank for /home";
      };
    };
  };
}
