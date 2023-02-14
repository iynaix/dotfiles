{ pkgs, host, user, ... }: {
  services = {
    transmission = { enable = true; };
    sonarr = { enable = true; };
  };

  home-manager.users.${user} = {
    home = {
      file.".config/transmission/settings.json" = {
        source = ./transmission/settings.json;
      };

      packages = with pkgs; [ transmission-remote-gtk ];
    };
  };
}
