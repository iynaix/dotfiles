{ config, ... }:
{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--ignore-file=${config.xdg.configHome}/ripgrep/.ignore"
    ];
  };

  xdg.configFile."ripgrep/.ignore".text = ''
    # global ignore file for ripgrep
    .envrc
    .ignore
    *.lock
    generated.nix
    generated.json
  '';
}
