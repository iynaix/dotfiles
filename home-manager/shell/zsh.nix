{user, ...}: let
  dotDir = ".config/zsh";
in {
  # NOTE: see shell.nix for shared aliases and initExtra
  programs.zsh = {
    enable = true;
    dotDir = dotDir;
    autocd = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    history.path = "/home/${user}/${dotDir}/.zsh_history";
    historySubstringSearch = {
      enable = true;
      # fix up and down arrows for substring search not working
      # https://reddit.com/r/zsh/comments/kae8yg/plugin_zshhistorysubstringsearch_not_working/
      searchUpKey = "^[OA";
      searchDownKey = "^[OB";
    };
    initExtra = ''
      # setup completions
      compdef _directories md
      _openproj() {
          _files -/ -W '/home/iynaix/projects/'
      }
      compdef _openproj openproj

      set -o emacs

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
}
