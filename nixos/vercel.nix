{
  pkgs,
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.vercel;
  vercel-backup = pkgs.writeShellApplication {
    name = "vercel-backup";
    runtimeInputs = [pkgs.postgresql_15];
    text = ''
      mkdir -p "/media/6TBRED/Vercel"

      VERCEL_POSTGRES="$(cat /run/secrets/vercel_postgres)"
      pg_dump "$VERCEL_POSTGRES" --file="/media/6TBRED/Vercel/vercel-coinfc-$(date +%F).sql"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      vercel_postgres.owner = user;
    };

    systemd.services.vercel-backup = {
      serviceConfig.Type = "oneshot";
      serviceConfig.User = user;
      script = "${vercel-backup}/bin/vercel-backup";
    };
    systemd.timers.vercel-backup = {
      wantedBy = ["timers.target"];
      partOf = ["vercel-backup.service"];
      timerConfig = {
        # every day at 5:03am
        OnCalendar = "*-*-* 05:03:00";
        Unit = "vercel-backup.service";
      };
    };
  };
}
