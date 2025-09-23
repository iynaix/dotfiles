{ pkgs, ... }:
let
  ignoreFile = pkgs.writeText "ripgrep-ignore" ''
    .envrc
    .ignore
    *.lock
    generated.nix
    generated.json
  '';
in
{
  custom.wrappers = [
    (
      { pkgs, ... }:
      {
        wrappers.ripgrep = {
          basePackage = pkgs.ripgrep;
          prependFlags = [
            "--smart-case"
            "--ignore-file"
            ignoreFile
          ];
        };
      }
    )
  ];

  environment.systemPackages = [ pkgs.ripgrep ];
}
