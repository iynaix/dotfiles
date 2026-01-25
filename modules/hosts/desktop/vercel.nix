{ lib, ... }:
{
  flake.nixosModules.host-desktop =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.custom.constants) user;
    in
    {
      sops.secrets.vercel_postgres.owner = user;

      custom.shell.packages = {
        vercel-backup = {
          runtimeInputs = [ pkgs.postgresql_15 ];
          text = # sh
            ''
              mkdir -p "/media/HGST10/Vercel"

              VERCEL_POSTGRES="$(cat ${config.sops.secrets.vercel_postgres.path})"
              pg_dump "$VERCEL_POSTGRES" --file="/media/HGST10/Vercel/vercel-coinfc-$(date +%F).sql"
            '';
        };
      };

      systemd = {
        services.vercel-backup = {
          serviceConfig.Type = "oneshot";
          serviceConfig.User = user;
          script = lib.getExe pkgs.custom.shell.vercel-backup;
        };
        timers.vercel-backup = {
          wantedBy = [ "timers.target" ];
          partOf = [ "vercel-backup.service" ];
          timerConfig = {
            # every 3 days at 13:52
            OnCalendar = "*-*-*/3 13:52:00";
            Unit = "vercel-backup.service";
          };
        };
      };

      custom.persist.home.directories = [ ".local/share/com.vercel.cli" ];
    };
}
