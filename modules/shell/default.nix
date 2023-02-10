{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      curl
      exa
      git
      ranger
      tmux
      wget
      zsh-powerlevel10k
    ];

    file.".config/git" = {
      source = ./gitconfig;
      recursive = true;
    };

    file.".config/tmux" = {
      source = ./tmux;
      recursive = true;
    };

    file.".config/zsh" = {
      source = ./zsh;
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
