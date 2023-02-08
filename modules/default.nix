{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      alacritty
      bspwm
      dunst
      git
      mpv
      polybar
      rofi
      sxiv
      sxhkd
      tmux
      yt-dlp
      zathura
      powerlevel10k
      zsh
    ];

    # TODO: bash?
    # TODO: xorg
    # TODO: neovim

    file."bin" = {
      source = ./bin;
      recursive = true;
    };

    file.".config/alacritty" = {
      source = ./alacritty;
      recursive = true;
    };

    file.".config/bspwm" = {
      source = ./bspwm;
      recursive = true;
    };

    file.".config/dunst" = {
      source = ./dunst;
      recursive = true;
    };

    file."." = {
      source = ./gitconfig;
      recursive = true;
    };

    file.".config/mpv" = {
      source = ./mpv;
      recursive = true;
    };

    file.".config/polybar" = {
      source = ./polybar;
      recursive = true;
    };

    file.".config/rofi" = {
      source = ./rofi;
      recursive = true;
    };

    file.".config/sxiv" = {
      source = ./sxiv;
      recursive = true;
    };

    file.".config/tmux" = {
      source = ./tmux;
      recursive = true;
    };

    file.".config/yt-dlp" = {
      source = ./yt-dlp;
      recursive = true;
    };

    file.".config/zathura" = {
      source = ./zathura;
      recursive = true;
    };

    file.".config/zsh" = {
      source = ./zsh;
      recursive = true;
    };

  };

  programs = {

  };
}
