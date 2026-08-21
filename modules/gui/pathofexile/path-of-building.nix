{
  packages =
    { libCustom, pkgs, ... }:
    let
      source = (libCustom.nvFetcherSources pkgs).rusty-path-of-building;
    in
    {
      # use latest version
      path-of-building = pkgs.rusty-path-of-building.overrideAttrs (
        source
        // {
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = source.src + "/Cargo.lock";
            allowBuiltinFetchGit = true;
          };
        }
      );
    };

  hosts = [
    "desktop"
    "framework"
  ];

  config =
    { pkgs, ... }:
    {
      # covers both poe1 and poe2
      environment.systemPackages = [
        pkgs.custom.path-of-building
      ];

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
