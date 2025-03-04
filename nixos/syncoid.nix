{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    syncoid.enable = mkEnableOption "syncoid";
  };

  config = mkIf config.custom.syncoid.enable {
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

      # 23:14 daily
      interval = "*-*-* 23:14:00";

      commands."truenas" = {
        source = "zroot/persist";
        target = "root@${user}-nas:NAS/desktop-backup";
        extraArgs = [
          "--no-sync-snap"
          "--delete-target-snapshots"
        ];
        localSourceAllow = config.services.syncoid.localSourceAllow ++ [ "mount" ];
        localTargetAllow = config.services.syncoid.localTargetAllow ++ [ "destroy" ];
      };
    };

    # persist syncoid .ssh
    custom.persist = {
      root.directories = [ "/var/lib/syncoid" ];
    };
  };
}
