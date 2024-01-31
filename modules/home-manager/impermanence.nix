{lib, ...}: {
  options.custom.persist = {
    home = {
      directories = lib.mkOption {
        default = [];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        default = [];
        description = "Files to persist in home directory";
      };
      cache = lib.mkOption {
        default = [];
        description = "Directories to persist, but not to snapshot";
      };
    };
  };
}
