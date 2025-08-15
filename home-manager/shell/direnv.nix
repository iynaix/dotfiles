_: {
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  custom.shell.packages = {
    mkdirenv = # sh
      ''nix flake init --template github:iynaix/dotfiles#"$1"'';
    redirenv = # sh
      ''rm -r .direnv .devenv'';
  };

  custom.persist = {
    home = {
      directories = [ ".local/share/direnv" ];
      cache.directories = [
        # python package managers
        ".cache/pip"
        ".cache/uv"
      ];
    };
  };
}
