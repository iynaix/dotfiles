{
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.docker;
  persistCfg = config.iynaix-nixos.persist;
in {
  config = lib.mkIf (cfg.enable || config.iynaix-nixos.distrobox.enable) {
    users.users.${user}.extraGroups = ["docker"];

    virtualisation.docker = {
      enable = true;
      storageDriver = lib.mkIf (config.iynaix-nixos.zfs.enable && !(persistCfg.tmpfs && persistCfg.erase.root)) "zfs";
    };

    iynaix-nixos.persist = {
      root.directories = [
        "/var/lib/docker"
      ];
    };
  };
}
