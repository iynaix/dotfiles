{ pkgs, ... }: {
  imports = [
    ./shell
    ./programs/alacritty.nix
    ./programs/mpv.nix
    ./desktop/gtk.nix
    ./desktop/bspwm.nix
  ];

  home = {
    packages = with pkgs; [ brave udiskie vscode zathura ];

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
    neovim = {
      enable = true;
      extraPackages = with pkgs; [ fzf gcc ];
    };
  };
}
