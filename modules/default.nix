{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      alacritty
      brave
      bspwm
      dunst
      git
      mpv
      polybar
      rofi
      sxiv
      sxhkd
      tmux
      vscode
      yt-dlp
      zathura
      zsh-powerlevel10k
    ];

    # TODO: bash .profile 
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
    alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 20;
          y = 12;
        };
        font = {
          normal = {
            family = "JetBrainsMono Nerd Font";
            style = "Medium";
          };
          bold = {
            style = "Bold";
          };
          italic = {
            style = "Italic";
          };
          bold_italic = {
            style = "Bold Italic";
          };
          size = 11;
        };
        selection.save_to_clipboard = true;
        # window.opacity = 0.5;
        import = ["~/.config/alacritty/catppuccin/catppuccin-mocha.yml"];
      };
    };
  };
}
