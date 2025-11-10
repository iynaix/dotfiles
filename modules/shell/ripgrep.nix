{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      ignoreFile = pkgs.writeText "ripgrep-ignore" ''
        .envrc
        .direnv
        .devenv
        .ignore
        *.lock
        generated.nix
        generated.json
      '';
    in
    {
      packages.ripgrep' = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.ripgrep;
        flags = {
          "--smart-case" = { };
          "--ignore-file" = ignoreFile;
        };
      };
    };

  flake.nixosModules.core =
    { pkgs, self, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          ripgrep = self.packages.${pkgs.stdenv.hostPlatform.system}.ripgrep';
        })
      ];

      environment.systemPackages = [
        pkgs.ripgrep # overlay-ed above
      ];
    };
}
