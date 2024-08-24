{ config, ... }:
{
  # use centralized cargo cache
  home.sessionVariables = rec {
    CARGO_HOME = "/persist/cache${config.xdg.dataHome}/.cargo";
    CARGO_TARGET_DIR = "${CARGO_HOME}/target";
    RUSTUP_HOME = "/persist/cache${config.xdg.dataHome}/.rustup";
  };

  # setup nvim for rust
  programs.nixvim.plugins = {
    lsp.servers = {
      rust-analyzer = {
        enable = true;
        # do not install the language server
        package = null;
        autostart = true;
        cmd = null;
        installCargo = false;
        installRustc = false;
        settings.check.command = "clippy";
      };
    };

    conform-nvim = {
      settings = {
        formatters_by_ft = {
          rust = [ "rustfmt" ];
        };
      };
    };
  };

  custom.shell.packages =
    let
      cargoBinCompletions = binaryName: {
        fishCompletion = ''
          function _cargo_bins
            cargo run --bin 2>&1 | string replace -rf '^\s+' ""
          end

          complete -c ${binaryName} -f -a '(_cargo_bins)'
        '';
        bashCompletion = ''
          _cargo_bins() {
            local bins
            bins=$(cargo run --bin 2>&1 | sed 's/^\s\+//')
            COMPREPLY=("''${bins}")
          }

          complete -F _cargo_bins ${binaryName}
        '';
      };
    in
    {
      # cargo will be provided via the nix-shell
      crb = {
        text = ''
          # if no arguments
          if [ $# -eq 0 ]; then
            cargo run --bin "$(basename "$(pwd)")";
          else
            cargo run --bin "$1" -- "''${@:2}";
          fi;
        '';
      } // cargoBinCompletions "crb";
      crrb = {
        text = ''
          # if no arguments
          if [ $# -eq 0 ]; then
            cargo run --release --bin "$(basename "$(pwd)")";
          else
            cargo run --release --bin "$1" -- "''${@:2}";
          fi;
        '';
      } // cargoBinCompletions "crrb";
    };

  custom.persist = {
    home = {
      cache = [
        ".local/share/.cargo"
        ".local/share/.rustup"
      ];
    };
  };
}
