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

  flake.modules.nixos.core =
    { pkgs, self, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.system}.ripgrep' ];
    };
}
