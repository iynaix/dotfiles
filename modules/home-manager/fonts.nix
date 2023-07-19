{lib, ...}: {
  options.iynaix = {
    font = {
      regular = lib.mkOption {
        type = lib.types.str;
        default = "Inter";
        description = "The font to use for regular text";
      };
      monospace = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        description = "The font to use for monospace text";
      };
    };
  };
}
