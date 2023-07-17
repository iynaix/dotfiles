{
  pkgs,
  user,
  config,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      programs = {
        # firefox dev edition
        firefox = {
          enable = true;
          package = pkgs.firefox-devedition-bin;
        };
      };
    };

    iynaix.persist.home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
