{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  hasNixpkgsRepo = host == "desktop" || host == "framework";
in
{
  programs = {
    git = {
      enable = true;
      userName = "Lin Xianyi";
      userEmail = "iynaix@gmail.com";
      difftastic = {
        enable = true;
        background = "dark";
      };
      extraConfig =
        {
          init = {
            defaultBranch = "main";
          };
          alias = {
            # blame with ignore whitespace and track movement across all commits
            blame = "blame -w -C -C -C";
            diff = "diff --word-diff";
            # git town
            append = "town append";
            contribute = "town contribute";
            diff-parent = "town diff-parent";
            hack = "town hack";
            kill = "town kill";
            observe = "town observe";
            park = "town park";
            prepend = "town prepend";
            propose = "town propose";
            rename-branch = "town rename-branch";
            repo = "town repo";
            set-parent = "town set-parent";
            ship = "town ship";
            sync = "town sync";
          };
          branch = {
            master = {
              merge = "refs/heads/master";
            };
            main = {
              merge = "refs/heads/main";
            };
            sort = "-committerdate";
          };
          diff = {
            tool = "nvim -d";
            guitool = "code";
            colorMoved = "default";
          };
          format = {
            pretty = "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset";
          };
          merge = {
            conflictstyle = "diff3";
          };
          pull = {
            rebase = true;
          };
          push = {
            default = "simple";
          };
          # reuse record resolution: git automatically resolves conflicts using the recorded resolution
          rerere = {
            enabled = true;
            autoUpdate = true;
          };
        }
        // lib.optionalAttrs hasNixpkgsRepo {
          # background maintenance for large git repos:
          # https://blog.gitbutler.com/git-tips-2-new-stuff-in-git/#git-maintenance
          maintenance = lib.mkIf (host == "desktop" || host == "framework") {
            repo = "/persist${config.home.homeDirectory}/projects/nixpkgs";
          };
        };
    };

    lazygit.enable = true;
  };

  home = {
    shellAliases = {
      dt = "difftastic";
      lg = "lazygit";
      gaa = "git add --all";
      gb = "git branch";
      gbrd = "git push origin -d";
      gcaam = "git add --all && git commit --amend";
      gcam = "git commit --amend";
      gco = "git checkout";
      gl = "git pull";
      glg = "git log";
      gm = "git merge";
      gp = "git push";
      gpf = "git push --force-with-lease";
      glc = ''git pull origin "$(git rev-parse --abbrev-ref HEAD)"'';
      gpc = ''git push origin "$(git rev-parse --abbrev-ref HEAD)"'';
      gpcf = ''git push origin --force-with-lease "$(git rev-parse --abbrev-ref HEAD)"'';
      gpatch = "git diff --no-ext-diff";
      gr = "cd $(git rev-parse - -show-toplevel)"; # cd back to root
      grh = "git reset --hard";
      gri = "git rebase --interactive";
      gst = "git status -s -b && echo && git log | head -n 1";
      gsub = "git submodule update --init --recursive";
      # access github page for the repo we are currently in
      github = "open `git remote -v | grep github.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git:/http:/git'`";
      # cleanup leftover files from merges
      mergeclean = "find . -type f -name '*.orig' -exec rm -f {} ;";
    };

    # stacked diffs
    packages = [ pkgs.git-town ];
  };

  # extra git functions
  custom.shell.packages = {
    # create a new branch and push it to origin
    gbc = ''
      git branch "$1"
      git checkout "$1"
    '';
    # delete a remote branch
    grd = {
      text = ''
        git branch -D "$1" || true
        git push origin --delete "$1"
      '';
      fishCompletion = ''
        function __git_remote_branches
          command git branch --no-color -r 2>/dev/null | \
            sed -e 's/^..//' -e 's/^origin\///' | \
            grep -vE 'HEAD|^main$|^master$'
        end

        complete -c grd -f -a '(__git_remote_branches)'
      '';
      bashCompletion = ''
        __git_remote_branches() {
            git branch --no-color -r 2>/dev/null | \
            sed -e 's/^..//' -e 's/^origin\///' | \
            grep -vE 'HEAD|^main$|^master$'
        }

        complete -F __git_remote_branches grd
      '';
    };
    # searches git history, can never remember this stupid thing
    # 2nd argument is target path and subsequent arguments are passed through
    gsearch = ''git log -S "$1" -- "''${2:-.}" "$*[2,-1]"'';
    # checkout main / master, whichever exists
    gmain = ''
      if git show-ref --verify --quiet refs/heads/master; then
          BRANCH="master"
      else
          BRANCH="main"
      fi

      git checkout "$BRANCH"
    '';
    # syncs with upstream
    gsync = {
      runtimeInputs = with pkgs; [
        config.programs.gh.package
        custom.shell.gmain
      ];
      text = ''
        REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
        BRANCH="''${1:-}"
        if [ -z "$BRANCH" ]; then
          if git show-ref --verify --quiet refs/heads/master; then
              BRANCH="master"
          else
              BRANCH="main"
          fi
        fi

        # check if repo is forked and sync with upstream if it is
        if gh repo view "iynaix/$REPO_NAME" >/dev/null 2>&1; then
            gh repo sync "iynaix/$REPO_NAME" -b "$BRANCH"
        fi
        git pull origin "$BRANCH"
      '';
    };
  };

  custom.persist = {
    home.directories = [
      ".config/lazygit"
      ".config/systemd" # git maintenance systemd timers
    ];
  };
}
