{ pkgs, ... }: {
  imports = [
    ./shell
    ./programs/alacritty.nix
    ./programs/mpv.nix
    ./desktop/gtk.nix 
  ];

  home = {
    packages = with pkgs; [
      brave
      bspwm
      dunst
      picom
      polybar
      rofi
      sxiv
      sxhkd
      vscode
      zathura
    ];

    # TODO: bspwm
    # TODO: picom

    file."bin" = {
      source = ./bin;
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

    file.".config/nvim" = {
      source = ./nvim;
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

    file.".config/zathura" = {
      source = ./zathura;
      recursive = true;
    };

  };

  programs = {
    # alacritty = {
    #   enable = true;
    #   settings = {
    #     window.padding = {
    #       x = 20;
    #       y = 12;
    #     };
    #     font = {
    #       normal = {
    #         family = "JetBrainsMono Nerd Font";
    #         style = "Medium";
    #       };
    #       bold = { style = "Bold"; };
    #       italic = { style = "Italic"; };
    #       bold_italic = { style = "Bold Italic"; };
    #       size = 11;
    #     };
    #     selection.save_to_clipboard = true;
    #     # window.opacity = 0.5;
    #     import = [ "~/.config/alacritty/catppuccin/catppuccin-mocha.yml" ];
    #   };
    # };
    neovim = {
      enable = true;
      extraPackages = with pkgs; [ fzf gcc ];
    };
  };
}
