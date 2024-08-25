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

  # add the custom completions for both fish and fish
  programs = {
    fish.functions = {
      __cargo_bins = ''cargo run --bin 2>&1 | string replace -rf '^\s+' ""'';
    };
    bash.initExtra = ''
      __cargo_bins() {
        local bins
        bins=$(cargo run --bin 2>&1 | sed 's/^\s\+//')
        COMPREPLY=("''${bins}")
      }
    '';
  };

  custom.shell.packages = {
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
      fishCompletion = "complete -c crb -f -a '(__cargo_bins)'";
      bashCompletion = "complete -F __cargo_bins crb";
    };
    crrb = {
      text = ''
        # if no arguments
        if [ $# -eq 0 ]; then
          cargo run --release --bin "$(basename "$(pwd)")";
        else
          cargo run --release --bin "$1" -- "''${@:2}";
        fi;
      '';
      fishCompletion = "complete -c crrb -f -a '(__cargo_bins)'";
      bashCompletion = "complete -F __cargo_bins crrb";
    };
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
