{ pkgs, user, ... }: {
  imports = [ ./zsh.nix ];

  home-manager.users.${user} = {
    home = {
      packages = with pkgs; [ bat bottom htop lazygit neofetch ranger rar tmux ];

      # ranger
      file.".shortcutrc".source = ./ranger/.shortcutrc;

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
      git = {
        enable = true;
        userName = "Lin Xianyi";
        userEmail = "iynaix@gmail.com";
        extraConfig = {
          init = { defaultBranch = "main"; };
          "branch.master" = { merge = "refs/heads/master"; };
          "branch.main" = { merge = "refs/heads/main"; };
          format = {
            pretty =
              "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset";
          };
          diff = {
            tool = "nvim -d";
            guitool = "code";
          };
          push = { default = "simple"; };
        };
        aliases = { reword = "!sh ~/bin/git-reword.sh"; };
      };
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
  };
}
