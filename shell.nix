{
  pkgs ? import <nixpkgs> { },
  ...
}:
pkgs.mkShell {
  packages = with pkgs; [
    age
    sops
    cachix
    deadnix
    statix
    nixd
    cargo-edit
    (writeShellScriptBin "crb" ''
      cargo run --manifest-path "packages/dotfiles-rs/Cargo.toml" --bin "$1" -- "''${@:2}"
    '')
    (writeShellScriptBin "crrb" ''
      cargo run --manifest-path "packages/dotfiles-rs/Cargo.toml" --release --bin "$1" -- "''${@:2}"
    '')
  ];

  env = {
    # Required by rust-analyzer
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  nativeBuildInputs = with pkgs; [
    cargo
    rustc
    rust-analyzer
    rustfmt
    clippy
    pkg-config
  ];

  buildInputs = with pkgs; [
    pre-commit
    # deps for building rust utilities
    glib
    gexiv2 # for reading metadata
  ];
}
