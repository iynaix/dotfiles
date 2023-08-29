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
      storageDriver = lib.mkIf config.iynaix-nixos.zfs.enable "zfs";
    };
  };
}
