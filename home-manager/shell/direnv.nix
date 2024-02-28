{
  config,
  lib,
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

    # silence direnv
    home.sessionVariables.DIRENV_LOG_FORMAT = "";

    custom.shell.functions = {
      # create a new devenv environment
      mkdevenv = {
        bashBody = "nix flake init --template github:iynaix/dotfiles#$1";
        fishBody = "nix flake init --template github:iynaix/dotfiles#$argv[1]";
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
