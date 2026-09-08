{ pkgs, ... }:
let
  crb = pkgs.writeShellScriptBin "crb" /* sh */ ''
    FEATURES_FLAG=""
    RELEASE_FLAG=""
    BINARY_NAME=""
    REST_ARGS=()

    # first arg in bin name
    if [[ $# -gt 0 ]]; then
        BINARY_NAME="$1"
        shift
    fi

    # use --features flag if provided
    while [[ $# -gt 0 ]]; do
        case $1 in
        --features)
            FEATURES_FLAG="--features $2"
            shift 2
            ;;
        --release)
            RELEASE_FLAG="--release"
            shift
            ;;
        *)
            REST_ARGS+=("$1")
            shift
            ;;
        esac
    done

    CARGO_ARGS=(cargo run --manifest-path "modules/gui/dotfiles-rs/Cargo.toml")
    [[ -n "$RELEASE_FLAG" ]] && CARGO_ARGS+=("$RELEASE_FLAG")
    [[ ''${#FEATURES[@]} -gt 0 ]] && CARGO_ARGS+=("''${FEATURES[@]}")
    CARGO_ARGS+=(--bin "$BINARY_NAME")
    if [[ ''${#REST_ARGS[@]} -gt 0 ]]; then
        CARGO_ARGS+=(--)
        CARGO_ARGS+=("''${REST_ARGS[@]}")
    fi

    echo "''${CARGO_ARGS[@]}"
    "''${CARGO_ARGS[@]}"
  '';
in
pkgs.mkShell {
  packages =
    with pkgs;
    [
      age
      sops
      cachix
      deadnix
      statix
      nil
      nixd
      nixfmt-rs
      pre-commit
      cargo-edit
      crb
      (pkgs.writeShellScriptBin "crrb" /* sh */ ''
        crb "$1" --release "''${@:2}"
      '')
    ]
    ++ [
      wlr-randr # used to get display info
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
