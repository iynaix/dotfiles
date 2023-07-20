{
  pkgs,
  isNixOS,
  ...
}: {
  config = {
    programs = {
      # firefox dev edition
      firefox = {
        enable = isNixOS;
        package = pkgs.firefox-devedition-bin;
      };
    };

    iynaix.persist.home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
