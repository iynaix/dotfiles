{
  lib,
  isNixOS,
  ...
}: {
  options.iynaix = {
    docker.enable = lib.mkEnableOption "docker";
    gnome3.enable = lib.mkEnableOption "gnome3";
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {default = true;};
    kmonad.enable = lib.mkEnableOption "kitty";
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = true;};
    smplayer.enable = lib.mkEnableOption "smplayer";
    torrenters.enable = lib.mkEnableOption "Torrenting Applications";
    virt-manager.enable = lib.mkEnableOption "virt-manager";
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
  };
}
