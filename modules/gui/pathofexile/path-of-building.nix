{ self, ... }:
{
  flake.nixosModules.programs_path-of-building =
    { pkgs, ... }:
    let
      source = (self.libCustom.nvFetcherSources pkgs).rusty-path-of-building;
    in
    {
      # covers both poe1 and poe2
      environment.systemPackages = [
        # use latest version
        (pkgs.rusty-path-of-building.overrideAttrs (
          source
          // {
            cargoDeps = pkgs.rustPlatform.importCargoLock {
              lockFile = source.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          }
        ))
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
