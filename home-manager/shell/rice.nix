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
  home = {
    packages =
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
      ++ optionals (!config.custom.headless) [
        imagemagick
      ];

    shellAliases = {
      neofetch = "fastfetch --config neofetch";
      wwfetch = "wfetch --wallpaper";
    };
  };

  # create xresources
  xresources = {
    path = "${config.xdg.configHome}/.Xresources";
    properties = {
      "Xft.dpi" = 96;
      "Xft.antialias" = true;
      "Xft.hinting" = true;
      "Xft.rgba" = "rgb";
      "Xft.autohint" = false;
      "Xft.hintstyle" = "hintslight";
      "Xft.lcdfilter" = "lcddefault";

      "*.font" = "JetBrainsMono Nerd Font Mono:Medium:size=12";
      "*.bold_font" = "JetBrainsMono Nerd Font Mono:Bold:size=12";
    };
  };
}
