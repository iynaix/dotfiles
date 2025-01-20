_: {
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  # vim support
  # programs.nixvim = {
  #   plugins.direnv.enable = true;
  #   globals = {
  #     direnv_silent_load = 1;
  #   };
  # };

  custom.shell.packages = {
    mkdevenv = ''nix flake init --template github:iynaix/dotfiles#"$1"'';
    redevenv = ''rm .direnv .devenv'';
    redirenv = ''rm .direnv .devenv'';
  };

  custom.persist = {
    home = {
      directories = [ ".local/share/direnv" ];
      cache.directories = [ ".cache/pip" ];
    };
  };
}
