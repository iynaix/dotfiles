{ pkgs, user, lib, config, ... }: {
  environment = {
    systemPackages = with pkgs; [ git ];
  };

  home-manager.users.${user} = {
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
          gco = "git checkout";
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
}
