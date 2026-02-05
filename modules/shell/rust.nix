{
  perSystem =
    { pkgs, ... }:
    {
      # runs rust using the direnv of specified directory
      packages.direnv-cargo-run = pkgs.writeShellApplication {
        name = "direnv-cargo-run";
        runtimeInputs = [ pkgs.direnv ];
        text = ''
          if [ $# -lt 1 ]; then
            echo "Usage: direnv-cargo-run <dir> [args...]" >&2
            exit 1
          fi

          dir="$1"
          shift

          bin="$(basename "$dir")"

          pushd "$dir" > /dev/null
          direnv exec "$dir" cargo run --release --bin "$bin" --manifest-path "$dir/Cargo.toml" -- "$@"
          popd > /dev/null
        '';
      };
    };

  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      xdgDataHome = config.hj.xdg.data.directory;
      # cargo will be provided via the nix-shell
      crb = pkgs.custom.writeShellApplicationCompletions {
        name = "crb";
        text = /* sh */ ''
          if [ $# -eq 0 ]; then
            cargo run --bin "$(basename "$(pwd)")"
          else
            cargo run --bin "$1" -- "''${@:2}"
          fi;
        '';
        completions.fish = "complete -c crb -f -a '(__cargo_bins)'";
        completions.bash = "complete -F __cargo_bins crb";
      };
      crrb = pkgs.custom.writeShellApplicationCompletions {
        name = "crrb";
        text = /* sh */ ''
          if [ $# -eq 0 ]; then
            cargo run --release --bin "$(basename "$(pwd)")"
          else
            cargo run --release --bin "$1" -- "''${@:2}"
          fi;
        '';
        completions.fish = "complete -c crrb -f -a '(__cargo_bins)'";
        completions.bash = "complete -F __cargo_bins crrb";
      };
    in
    {
      environment = {
        # use centralized cargo cache
        sessionVariables = rec {
          CARGO_HOME = "/cache${xdgDataHome}/.cargo";
          CARGO_TARGET_DIR = "${CARGO_HOME}/target";
          RUSTUP_HOME = "/cache${xdgDataHome}/.rustup";
        };

        systemPackages = [
          crb
          crrb
          pkgs.custom.direnv-cargo-run
        ];
      };

      # add the custom cargo bin completions for both bash and fish
      programs = {
        bash.shellInit = /* sh */ ''
          __cargo_bins() {
            local bins
            bins=$(cargo run --bin 2>&1 | sed 's/^\s\+//')
            COMPREPLY=("''${bins}")
          }
        '';
        fish.shellInit = /* fish */ ''
          function __cargo_bins
              cargo run --bin 2>&1 | string replace -rf '^\s+' ""
          end
        '';

      };

      custom.persist = {
        home = {
          cache.directories = [
            ".local/share/.cargo"
            ".local/share/.rustup"
          ];
        };
      };
    };
}
