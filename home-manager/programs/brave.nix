{pkgs, ...}: {
  home.packages = [pkgs.brave];

  custom.persist = {
    home.directories = [
      ".cache/BraveSoftware"
      ".config/BraveSoftware"
    ];
  };
}
