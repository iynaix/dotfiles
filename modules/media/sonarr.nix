{ pkgs, user, lib, config, ... }: {
  config = {
    services.sonarr.enable = true;

    # setup cron job to sync sonarr ical with google calendar
    # https://www.codyhiar.com/blog/repeated-tasks-with-systemd-service-timers-on-nixos/
    # timer format examples can be found at man systemd.time
    systemd.services.sonarr-ical-sync = {
      serviceConfig.Type = "oneshot";
      serviceConfig.User = user;
      path = with pkgs; [ direnv nix-direnv ];
      script = ''
        cd /home/${user}/projects/sonarr-ical-sync
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        yarn sync
      '';
    };
    systemd.timers.sonarr-ical-sync = {
      wantedBy = [ "timers.target" ];
      partOf = [ "sonarr-ical-sync.service" ];
      timerConfig = {
        # every 3h at 39min past the hour
        OnCalendar = "00/3:39:00";
        Unit = "sonarr-ical-sync.service";
      };
    };

    home-manager.users.${user} = {
      home = { };
    };

    iynaix.persist.root.directories = [
      "/var/lib/sonarr/.config/NzbDrone"
    ];
  };
}
