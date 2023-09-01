{
  config,
  lib,
  host,
  ...
}: let
  cfg = config.iynaix-nixos;
in {
  options.iynaix-nixos = {
    ### NIXOS LEVEL OPTIONS ###
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {default = cfg.distrobox.enable;};
    hyprland = {
      enable = lib.mkEnableOption "hyprland (nixos)";
      stable = lib.mkEnableOption "Use the stable version of Hyprland (v0.28.0)" // {default = true;};
    };
    kmonad.enable = lib.mkEnableOption "kmonad" // {default = host == "laptop";};
    sops.enable = lib.mkEnableOption "sops" // {default = true;};
    syncoid.enable = lib.mkEnableOption "syncoid";
    torrenters.enable = lib.mkEnableOption "Torrenting Applications";
    vercel.enable = lib.mkEnableOption "Vercel Backups";
    virt-manager.enable = lib.mkEnableOption "virt-manager";
  };
}
