{
  user,
  lib,
  config,
  pkgs,
  ...
}: let
  zdotdir = "/home/${user}/.config/zsh";
  histFile = "${zdotdir}/.zsh_history";
in {
  programs.zsh = {
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

    shellAliases =
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

    initExtra = ''
      function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
      compdef _directories md

      # Suppress output of loud commands you don't want to hear from
      q() { "$@" > /dev/null 2>&1; }

      # create a new devenv environment
      mkdevenv() {
          nix flake init --template github:iynaix/dotfiles#$1
      }

      # improved which for nix
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

      # wallust colorscheme
      ${lib.optionalString (config.iynaix.wallust.zsh) "cat ~/.cache/wallust/sequences"}
    '';
  };

  iynaix.persist.home = {
    files = [
      ".config/zsh/.zsh_history"
    ];
  };
}
