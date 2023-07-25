{
  lib,
  isNixOS,
  ...
}: {
  options.iynaix = {
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {default = isNixOS;};
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = isNixOS;};
    smplayer.enable = lib.mkEnableOption "smplayer";
    trimage.enable = lib.mkEnableOption "trimage";
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
  };
}
