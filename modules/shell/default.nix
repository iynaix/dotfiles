{ pkgs, user, lib, config, ... }: {
  imports = [ ./ranger.nix ./zsh.nix ];

  options.iynaix.shortcuts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      h = "~";
      c = "~/.config";
      vv = "~/Videos";
      vaa = "~/Videos/Anime";
      vac = "~/Videos/Anime/Current";
      vC = "~/Videos/Courses";
      vm = "~/Videos/Movies";
      vu = "~/Videos/US";
      vc = "~/Videos/US/Current";
      vn = "~/Videos/US/New";
      pp = "~/projects";
      pcf = "~/projects/coinfc";
      pcb = "~/projects/coinfc-backend";
      pe = "~/projects/ergodox-layout";
      PP = "~/Pictures";
      Ps = "~/Pictures/Screenshots";
      Pw = "~/Pictures/Wallpapers";
      dd = "~/Downloads";
      dp = "~/Downloads/pending";
      du = "~/Downloads/pending/Unsorted";
      dk = "/run/media/iynaix";
    };
    description = "Shortcuts for navigating across multiple terminal programs.";
  };

  config = {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [ bat bottom htop lazygit neofetch tmux ];

        file.".config/tmux" = {
          source = ./tmux;
          recursive = true;
        };
      };

      # potential vifm shortcuts
      # file.".config/vifm/vifmrc".text = lib.mkAfter (lib.concatStringsSep "\n"
      #   (lib.mapAttrsToList
      #     (name: value: (lib.concatStringsSep "\n" [
      #       "map g${name} :cd ${value}"
      #       "map t${name} <tab>:cd ${value} <CR><tab>"
      #       "map M${name} <tab>:cd ${value} <CR><tab>:mo<CR>"
      #       "map Y${name} <tab>:cd ${value} <CR><tab>:co<CR>"
      #     ]))
      #     config.iynaix.shortcuts));

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
  };
}
