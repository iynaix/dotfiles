{
  inputs,
  lib,
  ...
}:
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
          "--smart-case" = true;
          "--ignore-file" = toString ignoreFile;
        };
      };
    };

  flake.nixosModules.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          ripgrep = pkgs.custom.ripgrep';
        })
      ];

      environment.systemPackages = [
        pkgs.ripgrep # overlay-ed above
      ];

      custom.programs.print-config =
        let
          cmd = /* sh */ ''cat "${lib.getExe pkgs.ripgrep}"'';
        in
        {
          rg = cmd;
          ripgrep = cmd;
        };
    };
}
