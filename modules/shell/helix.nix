{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      helixConf = {
        theme = "tokyonight";
      };
    in
    {
      packages.helix' = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.helix;
        flags = {
          "--config" = tomlFormat.generate "config.toml" helixConf;
        };
      };
    };

  flake.nixosModules.helix =
    { pkgs, self, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.helix' ];
    };
}
