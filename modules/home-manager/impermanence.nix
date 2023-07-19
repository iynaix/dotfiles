{lib, ...}: {
  options.iynaix.persist = {
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
  };
}
