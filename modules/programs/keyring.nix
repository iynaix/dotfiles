{ config, pkgs, user, ... }:
{
  config = {
    # enable gnome-keyring for all users
    services.gnome.gnome-keyring.enable = true;

    home-manager.users.${user} = {
      home.packages = with pkgs;
        [
          gcr # stops errors with copilot login?
        ];

    };

    # persist keyring and misc other secrets
    iynaix.persist.home.directories = [
      { directory = ".gnupg"; mode = "0700"; }
      { directory = ".pki"; mode = "0700"; }
      { directory = ".ssh"; mode = "0700"; }
      { directory = ".local/share/keyrings"; mode = "0700"; }
    ];
  };
}
