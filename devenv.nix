{ inputs, pkgs, ... }:
inputs.devenv.lib.mkShell {
  inherit inputs pkgs;

  modules = [
    (
      { pkgs, ... }:
      {
        # devenv configuration
        packages = with pkgs; [
          age
          sops
          cachix
          deadnix
          statix
          nixd
          cargo-edit
        ];

        languages.rust.enable = true;

        pre-commit = {
          hooks = {
            deadnix = {
              enable = true;
              excludes = [
                "generated.nix"
                "templates/.*/flake.nix"
              ];
              settings = {
                edit = true;
              };
            };
            nixfmt-rfc-style = {
              enable = true;
              excludes = [ "generated.nix" ];
            };
            statix = {
              enable = true;
              excludes = [ "generated.nix" ];
            };
          };
        };
      }
    )
  ];
}
