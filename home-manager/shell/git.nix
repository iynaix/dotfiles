{pkgs, ...}: {
  home.packages = [
    pkgs.delta
    pkgs.lazygit
  ];

  programs = {
    gh = {
      enable = true;
      # https://github.com/nix-community/home-manager/issues/4744#issuecomment-1849590426
      settings = {
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        version = 1;
      };
    };
    git = {
      enable = true;
      userName = "Lin Xianyi";
      userEmail = "iynaix@gmail.com";
      extraConfig = {
        init = {defaultBranch = "main";};
        branch = {
          master = {merge = "refs/heads/master";};
          main = {merge = "refs/heads/main";};
        };
        core = {
          pager = "delta";
        };
        interactive = {
          diffFilter = "delta --color-only";
        };
        delta = {
          navigate = true;
          light = false;
          # side-by-side = true;
        };
        merge = {
          conflictstyle = "diff3";
        };
        format = {
          pretty = "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset";
        };
        diff = {
          tool = "nvim -d";
          guitool = "code";
          colorMoved = "default";
        };
        pull = {rebase = true;};
        push = {default = "simple";};
      };
    };
  };

  # extra git functions
  iynaix.shell.functions = {
    # delete a remote branch
    grd = ''
      gb -D $1
      gp origin --delete $1
    '';
    # searches git history, can never remember this stupid thing
    gsearch = {
      bashBody = ''
        # 2nd argument is target path and subsequent arguments are passed through
        git log -S$1 -- ''${2:-.} $*[2,-1]
      '';
      fishBody = ''
        # 2nd argument is target path and subsequent arguments are passed through
        git log -S$argv[1] -- $argv[2] $argv[3..-1]
      '';
    };
  };

  home.shellAliases = {
    lg = "lazygit";
    gaa = "git add --all";
    gb = "git branch";
    gbtr = "git bisect reset";
    gcaam = "git add --all && git commit --amend";
    gcam = "git commit --amend";
    gco = "git checkout";
    gdc = "git diff --cached";
    gdi = "git diff";
    gl = "git pull";
    glg = "git log";
    gm = "git merge";
    gp = "git push";
    glc = ''git pull origin "$(git rev-parse --abbrev-ref HEAD)"'';
    gpc = ''git push origin "$(git rev-parse --abbrev-ref HEAD)"'';
    groot = "cd $(git rev-parse - -show-toplevel)";
    grh = "git reset --hard";
    gri = "git rebase --interactive";
    gst = "git status -s -b && echo && git log | head -n 1";
    gsub = "git submodule update --init --recursive";
    # access github page for the repo we are currently in
    github = "open \`git remote -v | grep github.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git:/http:/git'\`";
    # cleanup leftover files from merges
    mergeclean = "find . -type f -name '*.orig' -exec rm -f {} \;";
  };

  iynaix.persist = {
    home.directories = [
      ".config/gh"
    ];
  };
}
