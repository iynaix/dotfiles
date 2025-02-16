{ config, ... }:
{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--ignore-file=${config.xdg.configHome}/ripgrep/.ignore"
    ];
  };

  xdg.configFile."ripgrep/.ignore".text = # sh
    ''
      # global ignore file for ripgrep
      .envrc
      .ignore
      *.lock
      generated.nix
      generated.json
    '';
}
