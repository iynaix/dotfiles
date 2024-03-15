{
  config,
  lib,
  pkgs,
  user,
  ...
}:
lib.mkMerge [
  {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # vim support
    programs.nixvim = {
      plugins.direnv.enable = true;
      globals = {
        direnv_silent_load = 1;
      };
    };

    home = {
      # silence direnv
      sessionVariables.DIRENV_LOG_FORMAT = "";

      packages = pkgs.custom.lib.createShellScriptBins {
        mkdevenv = "nix flake init --template github:iynaix/dotfiles#$1";
      };
    };

    custom.persist = {
      home = {
        directories = [ ".local/share/direnv" ];
        cache = [
          ".local/share/.cargo"
          ".cache/pip"
          ".cache/torch" # pytorch models
          ".cache/yarn"
        ];
      };
    };
  }

  # rust stuff
  {
    home.sessionVariables = {
      CARGO_HOME = "/persist/cache/${config.xdg.dataHome}/.cargo";
      CARGO_TARGET_DIR = "/persist/cache/home/${user}/cargo/target";
    };
  }
]
