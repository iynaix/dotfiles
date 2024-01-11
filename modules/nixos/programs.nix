{
  config,
  isLaptop,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos;
in {
  options.iynaix-nixos = {
    ### NIXOS LEVEL OPTIONS ###
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {default = cfg.distrobox.enable;};
    hyprland.enable = lib.mkEnableOption "hyprland (nixos)" // {default = true;};
    keyd.enable = lib.mkEnableOption "keyd" // {default = isLaptop;};
    syncoid.enable = lib.mkEnableOption "syncoid";
    bittorrent.enable = lib.mkEnableOption "Torrenting Applications";
    vercel.enable = lib.mkEnableOption "Vercel Backups";
    vm.enable = lib.mkEnableOption "VM support";
  };
}
