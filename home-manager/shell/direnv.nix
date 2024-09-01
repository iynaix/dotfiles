_: {
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
  };

  custom.shell.packages = {
    mkdevenv = ''nix flake init --template github:iynaix/dotfiles#"$1"'';
    rmdevenv = ''rm .direnv .devenv'';
    rmdirenv = ''rm .direnv .devenv'';
  };

  custom.persist = {
    home = {
      directories = [ ".local/share/direnv" ];
      cache.directories = [ ".cache/pip" ];
    };
  };
}
