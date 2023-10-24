{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  outputs = {
    nixpkgs,
    devenv,
    systems,
    ...
  } @ inputs: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    devShells =
      forEachSystem
      (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              # https://devenv.sh/reference/options/
              packages = with pkgs; [
              ];

              dotenv.disableHint = true;
              languages.python = {
                enable = true;
                package = pkgs.python3.withPackages (ps:
                  with ps; [
                    flake8
                    black
                  ]);
                venv.enable = true;
              };
            }
          ];
        };
      });
  };
}
