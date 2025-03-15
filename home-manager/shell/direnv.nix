_: {
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  custom.shell.packages = {
    mkdevenv = # sh
      ''nix flake init --template github:iynaix/dotfiles#"$1"'';
    redevenv = # sh
      ''rm .direnv .devenv'';
    redirenv = # sh
      ''rm .direnv .devenv'';
  };

  custom.persist = {
    home = {
      directories = [ ".local/share/direnv" ];
      cache.directories = [ ".cache/pip" ];
    };
  };
}
