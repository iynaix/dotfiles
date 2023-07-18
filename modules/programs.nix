{
  lib,
  isNixOS,
  ...
}: {
  options.iynaix = {
    docker.enable = lib.mkEnableOption "docker";
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {default = true;};
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = true;};
    virt-manager.enable = lib.mkEnableOption "virt-manager";
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
  };
}
