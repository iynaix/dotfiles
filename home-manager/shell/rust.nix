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
      formattersByFt = {
        rust = [ "rustfmt" ];
      };
    };
  };

  custom.shell.packages = {
    # cargo will be provided via the nix-shell
    crb = ''
      # if no arguments
      if [ $# -eq 0 ]; then
        cargo run --bin "$(basename "$(pwd)")";
      else
        cargo run --bin "$1" -- "''${@:2}";
      fi;
    '';
    crrb = ''
      # if no arguments
      if [ $# -eq 0 ]; then
        cargo run --release --bin "$(basename "$(pwd)")";
      else
        cargo run --release --bin "$1" -- "''${@:2}";
      fi;
    '';
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
