{
  pkgs,
  user,
  config,
  lib,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home = {
        file.".config/nvim" = {
          source = ./nvim;
          recursive = true;
        };
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        # withNodeJs = true;
        # withPython3 = true;
        extraPackages = with pkgs; [fzf gcc];
      };
    };

    iynaix.persist.home.directories = [
      ".vim"
      ".local/share/nvim" # data directory
      ".local/state/nvim" # persistent session info
    ];
  };
}
