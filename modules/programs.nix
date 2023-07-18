{
  lib,
  isNixOS,
  ...
}: {
  options.iynaix = {
    kitty.enable = lib.mkEnableOption "kitty" // {default = true;};
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = true;};
  };
}
