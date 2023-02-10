{ pkgs, ... }: {
  imports = [
    ./zsh.nix
  ];

  home = {
    packages = with pkgs; [
      curl
      exa
      git
      neofetch
      ranger
      tmux
      wget
    ];

    file.".config/git" = {
      source = ./gitconfig;
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
