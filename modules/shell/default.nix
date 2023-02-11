{ pkgs, ... }: {
  imports = [ ./zsh.nix ];

  home = {
    packages = with pkgs; [ bat htop lazygit neofetch ranger rar tmux ];

    file.".config/git" = {
      source = ./gitconfig;
      recursive = true;
    };

    # ranger
    file.".shortcutrc" = { source = ./ranger/.shortcutrc; };

    file.".config/ranger" = {
      source = ./ranger/ranger;
      recursive = true;
    };

    file.".config/tmux" = {
      source = ./tmux;
      recursive = true;
    };
  };

  programs = {
    yt-dlp = {
      enable = true;
      settings = {
        add-metadata = true;
        no-mtime = true;
        format = "best[ext=mp4]";
        sponsorblock-mark = "all";
        output = "%(title)s.%(ext)s";
      };
    };
  };
}
