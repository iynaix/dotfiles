{
  packages =
    { inputs, pkgs, ... }:
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
      ripgrep = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.ripgrep;
        flags = {
          "--smart-case" = true;
          "--ignore-file" = toString ignoreFile;
        };
      };
    };

  config =
    { lib, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          ripgrep = pkgs.custom.ripgrep;
        })
      ];

      environment.systemPackages = [
        pkgs.ripgrep # overlay-ed above
      ];

      custom.programs.print-config = rec {
        rg = /* sh */ ''moor --lang sh "${lib.getExe pkgs.ripgrep}"'';
        ripgrep = rg;
      };
    };
}
