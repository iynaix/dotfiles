{
  config,
  lib,
  ...
}: {
  options.iynaix-nixos = {
    ### NIXOS LEVEL OPTIONS ###
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {default = config.iynaix-nixos.distrobox.enable;};
    helix.enable = lib.mkEnableOption "helix";
    hyprland.enable = lib.mkEnableOption "hyprland";
    kmonad.enable = lib.mkEnableOption "kmonad";
    torrenters.enable = lib.mkEnableOption "Torrenting Applications";
    virt-manager.enable = lib.mkEnableOption "virt-manager";
  };
}
