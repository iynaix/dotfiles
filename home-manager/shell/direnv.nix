{pkgs, ...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # vim support
  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.direnv-vim];
  };

  home.sessionVariables = {
    # silence direnv
    DIRENV_LOG_FORMAT = "";
  };

  custom.shell.functions = {
    # create a new devenv environment
    mkdevenv = {
      bashBody = ''nix flake init --template github:iynaix/dotfiles#$1'';
      fishBody = ''nix flake init --template github:iynaix/dotfiles#$argv[1]'';
    };
  };

  custom.persist = {
    home.directories = [
      ".local/share/direnv"
    ];
    cache = [
      ".cargo"
      ".cache/pip"
      ".cache/torch" # pytorch models
      ".cache/yarn"
    ];
  };
}
