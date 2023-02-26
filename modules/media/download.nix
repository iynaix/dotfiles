{ pkgs, user, lib, ... }: {
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
      bookmarks = lib.mkAfter [
        "file:///media/6TBRED/Anime/Current TV Current"
        "file:///media/6TBRED/US/Current Anime Current"
        "file:///media/6TBRED/New TV New"
      ];
    };
  };
}
