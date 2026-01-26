{ lib, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.fzf ];

      programs = {
        bash.interactiveShellInit = /* sh */ ''
          if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
            eval "$(${lib.getExe pkgs.fzf} --bash)"
          fi
        '';

        fish.interactiveShellInit = /* fish */ ''
          ${lib.getExe pkgs.fzf} --fish | source
        '';
      };
    };
}
