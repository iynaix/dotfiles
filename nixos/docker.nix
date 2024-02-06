{
  user,
  lib,
  config,
  ...
}:
lib.mkIf (config.custom-nixos.docker.enable || config.custom-nixos.distrobox.enable) {
  users.users.${user}.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    storageDriver = lib.mkIf (config.fileSystems."/".fsType == "zfs") "zfs";
  };

  # store docker images on zroot/cache
  custom-nixos.persist = {
    root = {
      cache = [ "/var/lib/docker" ];
    };
  };
}
