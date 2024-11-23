{ config, lib, ... }:
{
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  # vim support
  programs.nixvim = {
    plugins.direnv.enable = true;
    globals = {
      direnv_silent_load = 1;
    };
  };

  custom.shell.packages = {
    # mkdevenv = ''nix flake init --template github:elias-ainsworth/dotfiles#"$1"'';
    mkdevenv = {
      text = lib.custom.direnvCargoRunQuiet {
        dir = "${config.home.homeDirectory}/projects/mkdevenv";
      };
    };
    rmdevenv = ''rm -rf .direnv .devenv'';
    rmdirenv = ''rm -rf .direnv .devenv'';
  };

  custom.persist = {
    home = {
      directories = [ ".local/share/direnv" ];
      cache.directories = [ ".cache/pip" ];
    };
  };
}
