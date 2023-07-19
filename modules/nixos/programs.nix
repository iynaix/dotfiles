{
  lib,
  # isNixOS,
  ...
}: {
  options.iynaix-nixos = {
    ### NIXOS LEVEL OPTIONS ###
    docker.enable = lib.mkEnableOption "docker";
    helix.enable = lib.mkEnableOption "helix";
    hyprland.enable = lib.mkEnableOption "hyprland";
    kmonad.enable = lib.mkEnableOption "kmonad";
    torrenters.enable = lib.mkEnableOption "Torrenting Applications";
    virt-manager.enable = lib.mkEnableOption "virt-manager";
  };
}
