{pkgs, ...}: {
  config = {
    programs = {
      # firefox dev edition
      firefox = {
        enable = true;
        package = pkgs.firefox-devedition-bin;
      };
    };

    iynaix.persist.home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
