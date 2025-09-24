{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;
in
{
  environment = {
    systemPackages =
      with pkgs;
      [
        asciiquarium
        cbonsai
        cmatrix
        fastfetch
        nitch
        pipes-rs
        scope-tui
        tenki
        terminal-colors
        (inputs.wfetch.packages.${pkgs.system}.default.override { iynaixos = true; })
      ]
      ++ optionals (config.custom.wm != "tty") [
        imagemagick
      ];

    shellAliases = {
      neofetch = "fastfetch --config neofetch";
      wwfetch = "wfetch --wallpaper";
    };
  };
}
