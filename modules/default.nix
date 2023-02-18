{ pkgs, user, ... }: {
  imports = [ ./shell ./programs ./desktop/gtk.nix ./desktop/bspwm.nix ];

  home-manager.users.${user} = {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
    };

    home = {
      packages = with pkgs; [ brave vscode zathura ];

      file.".config/nvim" = {
        source = ./nvim;
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

    };

    programs = {
      neovim = {
        enable = true;
        extraPackages = with pkgs; [ fzf gcc ];
      };
    };
  };
}
