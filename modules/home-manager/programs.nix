{
  host,
  isNixOS,
  lib,
  ...
}: {
  options.iynaix = {
    anime4k.enable = lib.mkEnableOption "anime4k" // {default = true;};
    deadbeef.enable = lib.mkEnableOption "deadbeef" // {default = host == "desktop";};
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {default = isNixOS;};
    obs-studio.enable = lib.mkEnableOption "obs-studio" // {default = isNixOS && host == "desktop";};
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = isNixOS;};
    rclip.enable = lib.mkEnableOption "rclip";
    trimage.enable = lib.mkEnableOption "trimage";
    vlc.enable = lib.mkEnableOption "vlc";
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
  };
}
