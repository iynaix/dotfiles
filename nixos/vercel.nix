{
  config,
  lib,
  pkgs,
  user,
  ...
}:
lib.mkIf (config.custom-nixos.vercel.enable && config.custom-nixos.sops.enable) {
  sops.secrets.vercel_postgres.owner = user;

  systemd = {
    services.vercel-backup = {
      serviceConfig.Type = "oneshot";
      serviceConfig.User = user;
      script = lib.getExe (
        pkgs.writeShellApplication {
          name = "vercel-backup";
          runtimeInputs = [ pkgs.postgresql_15 ];
          text = ''
            mkdir -p "/media/6TBRED/Vercel"

            VERCEL_POSTGRES="$(cat ${config.sops.secrets.vercel_postgres.path})"
            pg_dump "$VERCEL_POSTGRES" --file="/media/6TBRED/Vercel/vercel-coinfc-$(date +%F).sql"
          '';
        }
      );
    };
    timers.vercel-backup = {
      wantedBy = [ "timers.target" ];
      partOf = [ "vercel-backup.service" ];
      timerConfig = {
        # every day at 5:03am
        OnCalendar = "*-*-* 05:03:00";
        Unit = "vercel-backup.service";
      };
    };
  };

  custom-nixos.persist.home.directories = [ ".local/share/com.vercel.cli" ];
}
