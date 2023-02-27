{ pkgs, user, lib, ... }: {
  imports = [ ./transmission.nix ./sonarr.nix ];

  services = {
    sonarr = { enable = true; };
  };

  home-manager.users.${user} = {
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
