{ pkgs, user, lib, config, host, ... }: {
  config = {
    home-manager.users.${user} = {
      programs = {
        zsh = {
          enable = true;
          dotDir = ".config/zsh";
          autocd = true;
          enableCompletion = true;
          enableAutosuggestions = true;
          enableSyntaxHighlighting = true;
          history.path = "$ZDOTDIR/.zsh_history";
        };

        starship = {
          enable = true;
          enableZshIntegration = true;
          settings = {
            line_break = {
              disabled = true;
            };
          };
        };
      };

      programs.zsh.shellAliases =
        {
          ":e" = "nvim";
          ":q" = "exit";
          ":sp" = "bspc node -p south; $TERMINAL & disown";
          ":vs" = "bspc node -p east; $TERMINAL & disown";
          c = "clear";
          clearq = "rm -rf /tmp/q";
          isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
          ll = "ls -al";
          ls = "exa --group-directories-first --color-scale --icons";
          mergeclean = "find . -type f -name '*.orig' -exec rm -f {} \;";
          open = "xdg-open";
          pj = "openproj";
          py = "python";
          r = "ranger";
          showq = "touch /tmp/q && tail -f /tmp/q";
          subs = "subliminal download -l 'en' -l 'eng' -s";
          tree = "exa --group-directories-first --color-scale --icons --tree";
          v = "nvim";
          wget = "wget - -content-disposition";
          xclip = "xclip -selection c";
          yt = "yt-dlp";
          ytaudio = "yt --audio-format mp3 --extract-audio";
          ytsub = "yt --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
          ytplaylist = "yt --output '%(playlist_index)d - %(title)s.%(ext)s'";
          coinfc = "openproj coinfc";
          coinfc-backend = "openproj coinfc-backend && workon coinfc-backend";
          coinfcweb = "tmuxp load ~/.tmuxp/coinfcweb.yml";
          coinfcnative = "tmuxp load ~/.tmuxp/coinfcnative.yml";

          # cd aliases

          ".." = "cd..";
          "..." = "cd ../..";
          ".2" = "cd ../..";
          ".3" = "cd ../../..";
          ".4" = "cd ../../../..";
          ".5" = "cd ../../../../..";

          #git stuff
          gaa = "git add --all";
          gbr = "git bisect reset";
          gcaam = "gaa && gcam";
          gcam = "git commit --amend";
          gdc = "git diff --cached";
          gdi = "git diff";
          gl = "git pull";
          gp = "git push";
          glc = ''gl origin "$( git rev-parse --abbrev-ref HEAD )"'';
          gpc = ''gp origin "$( git rev-parse --abbrev-ref HEAD )"'';
          groot = "cd $(git rev-parse - -show-toplevel)";
          grh = "git reset --hard";
          gri = "git rebase --interactive";
          gst = "git status -s -b && echo && git log | head -n 1";
          gsub = "git submodule update --init --recursive";

          # access github page for the repo we are currently in
          github = "open \`git remote -v | grep github.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git:/http:/git'\`";

          gf = "git flow";
          gff = "gf feature";
          gffco = "gff checkout";
          gfh = "gf hotfix";
          gfr = "gf release";
          gfs = "gf support";
        } //
        # add zsh shortcuts
        lib.mapAttrs (name: value: "cd ${value}") config.iynaix.shortcuts;

      # TODO: upd8
      # add function aliases
      programs.zsh.initExtra = ''
        function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
        compdef _directories md

        # Suppress output of loud commands you don't want to hear from
        q() { "$@" > /dev/null 2>&1; }

        # switch / update via nix flake
        switch() {
            cd ~/projects/dotfiles
            sudo nixos-rebuild switch --flake ".#${host}"
        }

        upd8() {
            cd ~/projects/dotfiles
            nix flake update
            switch
        }

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

        # less verbose xev output with only the relevant parts
        keys() {
            xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
        }

        # server command, runs a local server
        server() {
            python3 -m http.server ''${1:-8000}
        }

        # searches git history, can never remember this stupid thing
        gsearch() {
            # 2nd argument is target path and subsequent arguments are passed thru
            glg -S$1 -- ''${2:-.} $*[2,-1]
        }

        # cd to project dir and open the virtualenv if it exists
        openproj () {
            cd ~/projects/
            if [[ $# -eq 1 ]]; then
                cd $1
            fi
        }
        _openproj() {
            _files -/ -W '/home/iynaix/projects/'
        }
        compdef _openproj openproj

        # emacs mode
        set -o emacs

        # Change cursor with support for inside/outside tmux
        function _set_cursor() {
            if [[ $TMUX = "" ]]; then
              echo -ne $1
            else
              echo -ne "\ePtmux;\e\e$1\e\\"
            fi
        }

        function _set_block_cursor() { _set_cursor '\e[2 q' }
        function _set_beam_cursor() { _set_cursor '\e[6 q' }

        function zle-keymap-select {
          if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
              _set_block_cursor
          else
              _set_beam_cursor
          fi
        }
        zle -N zle-keymap-select

        # ensure beam cursor when starting new terminal
        precmd_functions+=(_set_beam_cursor)
      '';
    };

    iynaix.persist.home = {
      files = [
        ".config/zsh/.zsh_history"
      ];
    };
  };
}
