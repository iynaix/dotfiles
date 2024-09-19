{
  config,
  inputs,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      asciiquarium
      cbonsai
      cmatrix
      fastfetch
      imagemagick
      nitch
      pipes-rs
      scope-tui
      tenki
      inputs.wfetch.packages.${pkgs.system}.wfetch
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

      "*.font" = "Iosevka Term Nerd Font Mono:Medium:size=12";
      "*.bold_font" = "Iosevka Term Nerd Font Mono:Bold:size=12";
    };
  };
}
