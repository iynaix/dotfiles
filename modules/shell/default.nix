{ pkgs, user, lib, config, ... }: {
  imports = [ ./ranger.nix ./tmux.nix ./zsh.nix ];

  options.iynaix.shortcuts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      h = "~";
      dots = "~/projects/dotfiles";
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
        packages = with pkgs; [ bat bottom htop lazygit neofetch ];
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

        # extra git stuff for zsh
        zsh = {
          shellAliases = {
            gaa = "git add --all";
            gbr = "git bisect reset";
            gcaam = "gaa && gcam";
            gcam = "git commit --amend";
            gdc = "git diff --cached";
            gdi = "git diff";
            gl = "git pull";
            glg = "git log";
            gp = "git push";
            glc = ''gl origin "$( git rev-parse --abbrev-ref HEAD )"'';
            gpc = ''gp origin "$( git rev-parse --abbrev-ref HEAD )"'';
            groot = "cd $(git rev-parse - -show-toplevel)";
            grh = "git reset --hard";
            gri = "git rebase --interactive";
            gst = "git status -s -b && echo && git log | head -n 1";
            gsub = "git submodule update --init --recursive";
            # git flow
            gf = "git flow";
            gff = "gf feature";
            gffco = "gff checkout";
            gfh = "gf hotfix";
            gfr = "gf release";
            gfs = "gf support";
            # access github page for the repo we are currently in
            github = "open \`git remote -v | grep github.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git:/http:/git'\`";
            # cleanup leftover files from merges
            mergeclean = "find . -type f -name '*.orig' -exec rm -f {} \;";
          };

          initExtra = ''
            # checkout and pull and merge gitflow branch
            gffp() {
                gffco $1 && gp
            }

            # delete a remote branch
            grd() {
                gb -D $1
                gp origin --delete $1
            }

            # delete a remote feature branch
            gffrd() {
                gb -D feature/$1
                gp origin --delete feature/$1
            }

            # searches git history, can never remember this stupid thing
            gsearch() {
                # 2nd argument is target path and subsequent arguments are passed thru
                git log -S$1 -- ''${2:-.} $*[2,-1]
            }
          '';
        };
      };
    };
  };
}
