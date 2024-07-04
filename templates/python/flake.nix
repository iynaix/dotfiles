{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            packages =
              (with pkgs.python3Packages; [
                flake8
                black
              ])
              ++ (with pkgs; [ ]);

            dotenv.disableHint = true;
            languages.python = {
              enable = true;
              venv.enable = true;
            };
          };
        };
    };
}
