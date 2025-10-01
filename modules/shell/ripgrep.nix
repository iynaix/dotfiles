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
    (_: _prev: {
      ripgrep = {
        flags = {
          "--smart-case" = { };
          "--ignore-file" = ignoreFile;
        };
      };
    })
  ];

  environment.systemPackages = [ pkgs.ripgrep ];
}
