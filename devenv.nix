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
          pkg-config
          glib
          gexiv2 # for reading metadata
        ];

        languages.rust.enable = true;

        scripts = {
          crb.exec = # sh
            ''
              cargo run --manifest-path "packages/dotfiles-rs/Cargo.toml" --bin "$1" -- "''${@:2}"
            '';

          crrb.exec = # sh
            ''
              cargo run --manifest-path "packages/dotfiles-rs/Cargo.toml" --release --bin "$1" -- "''${@:2}"
            '';
        };

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
