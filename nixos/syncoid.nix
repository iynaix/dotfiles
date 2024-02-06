{
  config,
  lib,
  user,
  ...
}:
lib.mkIf config.custom-nixos.syncoid.enable {
  # allow syncoid to ssh into NAS
  users.users = {
    syncoid.openssh.authorizedKeys.keyFiles = [
      ../home-manager/id_rsa.pub
      ../home-manager/id_ed25519.pub
    ];
  };

  # sync zfs to NAS on desktop
  services.syncoid = {
    enable = true;

    # 3:14am daily
    interval = "*-*-* 03:14:00";

    commands."truenas" = {
      source = "zroot/persist";
      target = "root@${user}-nas:NAS/desktop-backup";
      extraArgs = [
        "--no-sync-snap"
        "--delete-target-snapshots"
        "--sshoption=StrictHostKeyChecking=no"
      ];
      localSourceAllow = config.services.syncoid.localSourceAllow ++ [ "mount" ];
      localTargetAllow = config.services.syncoid.localTargetAllow ++ [ "destroy" ];
    };
  };

  # persist syncoid .ssh
  custom-nixos.persist = {
    root.directories = [ "/var/lib/syncoid" ];
  };
}
