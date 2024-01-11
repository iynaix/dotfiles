{
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.docker;
in {
  config = lib.mkIf (cfg.enable || config.iynaix-nixos.distrobox.enable) {
    users.users.${user}.extraGroups = ["docker"];

    virtualisation.docker = {
      enable = true;
      storageDriver = lib.mkIf (config.fileSystems."/".fsType == "zfs") "zfs";
    };

    # store docker images on zroot/cache
    environment.persistence."/persist/cache/docker" = {
      hideMounts = true;

      directories = [
        "/var/lib/docker"
      ];
    };
  };
}
