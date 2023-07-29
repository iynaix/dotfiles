{
  config,
  lib,
  host,
  ...
}: {
  options.iynaix-nixos = {
    ### NIXOS LEVEL OPTIONS ###
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {default = config.iynaix-nixos.distrobox.enable;};
    hyprland-nixos.enable = lib.mkEnableOption "hyprland (nixos)";
    kmonad.enable = lib.mkEnableOption "kmonad" // {default = host == "laptop";};
    sops.enable = lib.mkEnableOption "sops" // {default = config.iynaix-nixos.torrenters.enable;};
    torrenters.enable = lib.mkEnableOption "Torrenting Applications";
    virt-manager.enable = lib.mkEnableOption "virt-manager";
  };
}
