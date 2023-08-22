{...}: {
  # NOTE: see shell.nix for shared aliases and initExtra
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyFile = "$HOME/.config/bash/.bash_history";

    initExtra = ''
      # set starting cursor to blinking beam
      # echo -e -n "\x1b[\x35 q"
      _set_beam_cursor
    '';
  };

  iynaix.persist.home = {
    files = [
      ".config/bash/.bash_history"
    ];
  };
}
