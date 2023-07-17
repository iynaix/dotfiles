{lib, ...}: {
  options.iynaix.persist = {
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
    tmpfs = {
      root = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable tmpfs for /";
      };
      home = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable tmpfs for /home";
      };
    };
  };
}
