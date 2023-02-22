{ pkgs, user, ... }: {
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

    # extra media specific settings
    gtk.gtk3 = {
      bookmarks = [
        "file:///media/6TBRED/Anime/Current"
        "file:///media/6TBRED/US/Current"
        "file:///media/6TBRED/New"
      ];
    };
  };
}
