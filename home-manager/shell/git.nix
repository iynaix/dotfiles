{pkgs, ...}: let
  git-reword = pkgs.writeShellScriptBin "git-reword.sh" ''
    if [ -z "$1" ];
    then
        echo "No SHA provided. Usage: \"git reword <SHA>\"";
        exit 1;
    fi;
    if [ $(git rev-parse $1) == $(git rev-parse HEAD) ];
    then
        echo "$1 is the current commit on this branch.  Use \"git commit --amend\" to reword the current commit.";
        exit 1;
    fi;
    git merge-base --is-ancestor $1 HEAD;
    ANCESTRY=$?;
    if [ $ANCESTRY -eq 1 ];
    then
        echo "SHA is not an ancestor of HEAD.";
        exit 1;
    elif [ $ANCESTRY -eq 0 ];
    then
        git stash;
        START=$(git rev-parse --abbrev-ref HEAD);
        git branch savepoint;
        git reset --hard $1;
        git commit --amend;
        git rebase -p --onto $START $1 savepoint;
        git checkout $START;
        git merge savepoint;
        git branch -d savepoint;
        git stash pop;
    else
        exit 2;
    fi
  '';
in {
  home.packages = [git-reword];

  programs = {
    git = {
      enable = true;
      userName = "Lin Xianyi";
      userEmail = "iynaix@gmail.com";
      extraConfig = {
        init = {defaultBranch = "main";};
        "branch.master" = {merge = "refs/heads/master";};
        "branch.main" = {merge = "refs/heads/main";};
        format = {
          pretty = "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset";
        };
        diff = {
          tool = "nvim -d";
          guitool = "code";
        };
        pull = {rebase = true;};
        push = {default = "simple";};
      };
      aliases = {reword = "!sh ${git-reword}/bin/git-reword";};
    };

    # extra git stuff for zsh
    zsh = {
      shellAliases = {
        gaa = "git add --all";
        gb = "git branch";
        gbtr = "git bisect reset";
        gcaam = "gaa && gcam";
        gcam = "git commit --amend";
        gco = "git checkout";
        gdc = "git diff --cached";
        gdi = "git diff";
        gl = "git pull";
        glg = "git log";
        gm = "git merge";
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
}
