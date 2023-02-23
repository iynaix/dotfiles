{ pkgs, user, lib, config, host, ... }: {
  config = {
    # set as default shell for user
    environment.shells = [ pkgs.zsh ];

    home-manager.users.${user} = {
      home.sessionPath = [ "$HOME/bin" ];

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
          c = "clear";
          isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
          ll = "ls -al";
          ls = "exa --group-directories-first --color-scale --icons";
          open = "xdg-open";
          pj = "openproj";
          py = "python";
          r = "ranger";
          # subs = "subliminal download -l 'en' -l 'eng' -s";
          tree = "exa --group-directories-first --color-scale --icons --tree";
          v = "nvim";
          wget = "wget - -content-disposition";
          xclip = "xclip -selection c";
          coinfc = "openproj coinfc";

          # cd aliases
          ".." = "cd..";
          "..." = "cd ../..";
          ".2" = "cd ../..";
          ".3" = "cd ../../..";
          ".4" = "cd ../../../..";
          ".5" = "cd ../../../../..";
        } //
        # add zsh shortcuts
        lib.mapAttrs (name: value: "cd ${value}") config.iynaix.shortcuts;

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

        # less verbose xev output with only the relevant parts
        keys() {
            xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
        }

        # server command, runs a local server
        server() {
            python3 -m http.server ''${1:-8000}
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
