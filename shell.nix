{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  crb =
    pkgs.writeShellScriptBin "crb" # sh
      ''
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

        # no features provided, use WM detection
        if [[ -z "$FEATURES_FLAG" ]]; then
            if command -v hyprctl &>/dev/null; then
                FEATURES_FLAG="--features hyprland"
            elif command -v niri &>/dev/null; then
                FEATURES_FLAG="--features niri"
            elif command -v mmsg &>/dev/null; then
                FEATURES_FLAG="--features mango"
            fi
        fi

        CARGO_CMD="cargo run --manifest-path \"packages/dotfiles-rs/Cargo.toml\" $RELEASE_FLAG"
        if [[ -n "$FEATURES_FLAG" ]]; then
            CARGO_CMD="$CARGO_CMD $FEATURES_FLAG"
        fi

        # Add --bin with the binary name and remaining arguments
        CARGO_CMD="$CARGO_CMD --bin $BINARY_NAME"

        # Add remaining arguments if any
        if [[ ''${#REST_ARGS[@]} -gt 0 ]]; then
            CARGO_CMD="$CARGO_CMD -- ''${REST_ARGS[*]}"
        fi

        echo "$CARGO_CMD"
        eval "$CARGO_CMD"
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
      # FIXME: remove on new release of statix
      (statix.overrideAttrs (_o: rec {
        src = fetchFromGitHub {
          owner = "oppiliappan";
          repo = "statix";
          rev = "43681f0da4bf1cc6ecd487ef0a5c6ad72e3397c7";
          hash = "sha256-LXvbkO/H+xscQsyHIo/QbNPw2EKqheuNjphdLfIZUv4=";
        };

        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };
      }))
      nixd
      nixfmt
      pre-commit
      cargo-edit
      crb
      (pkgs.writeShellScriptBin "crrb" # sh
        ''
          crb "$1" --release "''${@:2}"
        ''
      )
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
