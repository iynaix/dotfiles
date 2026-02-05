{ inputs, lib, ... }:
{
  flake.nixosModules.core =
    {
      config,
      pkgs,
      ...
    }:
    let
      gitignores = [
        ".direnv"
        ".devenv"
        ".jj"
        "node_modules"
      ];
      # checkout main / master, whichever exists
      gmain = pkgs.writeShellApplication {
        name = "gmain";
        text = /* sh */ ''
          if git show-ref --verify --quiet refs/heads/master; then
              BRANCH="master"
          else
              BRANCH="main"
          fi

          git checkout "$BRANCH"
        '';
      };
      # create a new branch and push it to origin
      gbc = pkgs.writeShellApplication {
        name = "gbc";
        text = /* sh */ ''
          git branch "$1"
          git checkout "$1"
        '';
      };
      # delete a remote branch
      grd = pkgs.writeShellApplicationCompletions {
        name = "grd";
        text = /* sh */ ''
          git branch -D "$1" || true
          git push origin --delete "$1"
        '';
        completions.fish = /* fish */ ''
          function __git_remote_branches
            command git branch --no-color -r 2>/dev/null | \
              sed -e 's/^..//' -e 's/^origin\///' | \
              grep -vE 'HEAD|^main$|^master$'
          end

          complete -c grd -f -a '(__git_remote_branches)'
        '';
        completions.bash = /* sh */ ''
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
      grg = pkgs.writeShellApplication {
        name = "grg";
        text = /* sh */ ''git log -S "$1" -- "''${2:-.}" "$*[2,-1]"'';
      };
      # syncs with upstream
      gsync = pkgs.writeShellApplication {
        name = "gsync";
        runtimeInputs = [
          pkgs.gh
          gmain
        ];
        text = /* sh */ ''
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
    in
    lib.mkMerge [
      {
        programs = {
          git = {
            enable = true;

            config = {
              init = {
                defaultBranch = "main";
              };
              alias = {
                # blame with ignore whitespace and track movement across all commits
                blame = "blame -w -C -C -C";
                diff = "diff --word-diff";
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
              core = {
                excludesFile = pkgs.writeText ".gitignore" (lib.concatStringsSep "\n" gitignores);
              };
              diff = {
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
              user = {
                name = "Lin Xianyi";
                email = "iynaix@gmail.com";
              };
            };
          };

          lazygit.enable = true;
        };

        environment.shellAliases = {
          dt = "difftastic";
          lg = "lazygit";
          gaa = "git add --all";
          gb = "git branch";
          gbrd = "git push origin -d";
          gcaam = "git add --all && git commit --amend";
          gcam = "git commit --amend";
          gco = "git checkout";
          gcp = "git cherry-pick";
          gdiff = "git diff --no-ext-diff";
          gl = "git pull";
          glg = "git log";
          gm = "git merge";
          gp = "git push";
          fgp = "git push --force-with-lease";
          glc = ''git pull origin "$(git rev-parse --abbrev-ref HEAD)"'';
          gpc = ''git push origin "$(git rev-parse --abbrev-ref HEAD)"'';
          fgpc = ''git push origin --force-with-lease "$(git rev-parse --abbrev-ref HEAD)"'';
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

        # extra git functions
        environment.systemPackages = [
          gmain
          gbc
          grd
          grg
          gsync
        ];

        custom.persist = {
          home.directories = [
            ".config/lazygit"
            ".config/gitbutler"
          ];
        };
      }

      # difftastic
      {
        nixpkgs.overlays = [
          (_: prev: {
            difftastic' = inputs.wrappers.lib.wrapPackage {
              pkgs = prev;
              package = prev.difftastic;
              flags = {
                "--background" = "dark";
              };
            };
          })
        ];

        environment.systemPackages = [
          pkgs.difftastic # overlay-ed above
        ];

        programs.git.config = {
          diff = {
            tool = "difftastic";
          };
          difftool = {
            difftastic = {
              cmd = "difft $LOCAL $REMOTE";
            };
          };
        };
      }

      # git maintenance for large repos
      # https://blog.gitbutler.com/git-tips-2-new-stuff-in-git/#git-maintenance
      {
        programs.git.config = {
          maintenance = {
            repo = "/persist${config.hj.directory}/projects/nixpkgs";
          };
        };
      }
    ];
}
