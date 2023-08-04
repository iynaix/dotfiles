{
  user,
  lib,
  config,
  host,
  pkgs,
  ...
}: let
  zdotdir = "/home/${user}/.config/zsh";
  histFile = "${zdotdir}/.zsh_history";
in {
  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      autocd = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      history.path = histFile;
      historySubstringSearch = {
        enable = true;
        # fix up and down arrows for substring search not working
        # https://reddit.com/r/zsh/comments/kae8yg/plugin_zshhistorysubstringsearch_not_working/
        searchUpKey = "^[OA";
        searchDownKey = "^[OB";
      };
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        line_break = {
          disabled = true;
        };
        format = lib.concatStringsSep "" [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$nix_shell"
          # "$cmd_duration"
          # "$line_break"
          # "$python"
          "$character"
        ];
        character = {
          error_symbol = "[❯](red)";
          success_symbol = "[❯](purple)";
          vimcmd_symbol = "[❮](green)";
        };
        cmd_duration = {
          format = "[$duration]($style) ";
          style = "yellow";
        };
        directory = {
          style = "blue";
        };
        git_branch = {
          format = "[$branch]($style)";
          style = "yellow";
        };
        git_state = {
          format = "\([$state( $progress_current/$progress_total)]($style)\) ";
          style = "bright-black";
        };
        git_status = {
          conflicted = "​";
          deleted = "​";
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
          modified = "​";
          renamed = "​";
          staged = "​";
          stashed = "≡";
          style = "cyan";
          untracked = "​";
        };
        nix_shell = {
          format = "[$symbol]($style)";
          style = "blue";
        };
        # python = {
        #   format = "[$virtualenv]($style) ";
        #   style = "bright-black";
        # };
      };
    };
  };

  programs.zsh.shellAliases =
    {
      ":e" = "nvim";
      ":q" = "exit";
      c = "clear";
      btop = "btop --preset 2";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      nano = "nvim";
      nsh = "nix-shell -p";
      open = "xdg-open";
      lg = "lazygit";
      pj = "openproj";
      py = "python";
      r = "lf";
      # subs = "subliminal download -l 'en' -l 'eng' -s";
      t = "exa --tree";
      v = "nvim";
      wget = "wget - -content-disposition";
      coinfc = "openproj coinfc";

      # cd aliases
      ".." = "cd ..";
      "..." = "cd ../..";
      ".2" = "cd ../..";
      ".3" = "cd ../../..";
      ".4" = "cd ../../../..";
      ".5" = "cd ../../../../..";
    }
    //
    # add zsh shortcuts
    lib.mapAttrs (name: value: "cd ${value}") config.iynaix.shortcuts;

  programs.zsh.initExtra = ''
    function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
    compdef _directories md

    # Suppress output of loud commands you don't want to hear from
    q() { "$@" > /dev/null 2>&1; }

    # create a new devenv environment
    mkdevenv() {
        nix flake init --template github:iynaix/dotfiles#$1
    }

    # less verbose xev output with only the relevant parts
    keys() {
        xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
    }

    where() {
        readlink -f $(which $1)
    }

    # server command, runs a local server
    server() {
        ${pkgs.python3}/bin/python -m http.server ''${1:-8000}
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

    renamer() {
        pushd ~/projects/personal-graphql
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        yarn renamer
        popd
    }

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

    # disable empty line when opening new terminal, but
    # insert empty line after each command for starship
    # https://github.com/starship/starship/issues/560#issuecomment-1318462079
    precmd() { precmd() { echo "" } }

    # wallust colorscheme
    ${lib.optionalString (config.iynaix.wallust.zsh) "cat ~/.cache/wallust/sequences"}
  '';

  iynaix.persist.home = {
    files = [
      ".config/zsh/.zsh_history"
    ];
  };
}
