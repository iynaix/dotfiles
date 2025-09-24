{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
in
{
  environment.systemPackages = [ pkgs.fzf ];

  programs = {
    bash.interactiveShellInit = # sh
      ''
        if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
          eval "$(${getExe pkgs.fzf} --bash)"
        fi
      '';

    fish.interactiveShellInit = # fish
      ''
        ${getExe pkgs.fzf} --fish | source
      '';
  };
}
