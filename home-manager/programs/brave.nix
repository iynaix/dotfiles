{pkgs, ...}: {
  home.packages = [pkgs.brave];

  iynaix.persist = {
    home.directories = [
      ".cache/BraveSoftware"
      ".config/BraveSoftware"
    ];
  };
}
