{ config, pkgs, user, ... }:
{
  config = {
    # enable gnome-keyring for all users
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm.enableGnomeKeyring = true;

    home-manager.users.${user} = {
      home.packages = with pkgs;
        [
          gcr # stops errors with copilot login?
        ];

    };

    # persist keyring info
    iynaix.persist.home.directories = [ ".local/share/keyrings" ];
  };
}
