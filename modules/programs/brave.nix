{ pkgs, user, config, ... }:
{
  config = {
    home-manager.users.${user} = {
      home.packages = [ pkgs.brave ];
    };

    iynaix.persist.home.directories = [
      ".cache/BraveSoftware"
      ".config/BraveSoftware"
    ];
  };
}
