{lib, ...}: {
  options.iynaix = {
    kitty.enable = lib.mkEnableOption "kitty" // {default = true;};
  };
}
