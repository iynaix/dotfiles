{
  flake.nixosModules.path-of-building =
    { pkgs, ... }:
    {
      # covers both poe1 and poe2
      environment.systemPackages = [ pkgs.rusty-path-of-building ];

      custom.persist = {
        home = {
          directories = [
            ".local/share/RustyPathOfBuilding1"
            ".local/share/RustyPathOfBuilding2"
          ];
        };
      };
    };
}
