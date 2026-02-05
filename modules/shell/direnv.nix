{
  flake.nixosModules.core =
    { pkgs, ... }:
    let
      mkdirenv = pkgs.writeShellApplication {
        name = "mkdirenv";
        text = /* sh */ ''nix flake init --template github:iynaix/dotfiles#"$1"'';
      };
      redirenv = pkgs.writeShellApplication {
        name = "redirenv";
        text = /* sh */ "rm -r .direnv .devenv";
      };
    in
    {
      programs.direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };

      environment.systemPackages = [
        pkgs.direnv
        mkdirenv
        redirenv
      ];

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
    };
}
