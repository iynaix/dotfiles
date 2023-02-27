{ pkgs, user, lib, config, ... }: {
  config = {
    services = {
      sonarr = {
        enable = true;
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
