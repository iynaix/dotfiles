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
    iynaix.persist.home = {
      directories = [
        ".gnupg"
        ".pki"
        ".ssh"
        ".local/share/keyrings"
      ];
      files = [
        ".ssh/id_rsa"
      ];
    };
  };
}
