{ pkgs, ... }: {
  home = {
    file.".config/alacritty" = {
      source = ./alacritty;
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
          bold = { style = "Bold"; };
          italic = { style = "Italic"; };
          bold_italic = { style = "Bold Italic"; };
          size = 11;
          };
          selection.save_to_clipboard = true;
          # window.opacity = 0.5;
          import = [ "~/.config/alacritty/catppuccin-mocha.yml" ];
      };
    };
  };
}

       
