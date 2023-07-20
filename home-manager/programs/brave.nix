{
  pkgs,
  isNixOS,
  lib,
  ...
}: {
  home.packages = lib.mkIf isNixOS [pkgs.brave];

  iynaix.persist.home.directories = [
    ".cache/BraveSoftware"
    ".config/BraveSoftware"
  ];
}
