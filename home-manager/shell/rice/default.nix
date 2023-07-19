{pkgs, ...}: {
  imports = [
    ./cava.nix
    ./neofetch.nix
  ];

  home.packages = with pkgs; [
    cbonsai
    cmatrix
    imagemagick
    neofetch
    nitch
    pipes
  ];

  # create xresources
  xresources.properties = {
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
}
