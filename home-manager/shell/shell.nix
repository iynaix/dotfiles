# create a cross shell config
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.shell;
in {
  home.shellAliases =
    {
      ":e" = "nvim";
      ":q" = "exit";
      c = "clear";
      btop = "btop --preset 2";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      nano = "nvim";
      open = "xdg-open";
      pj = "openproj";
      py = "python";
      r = "lf";
      t = "exa --tree";
      v = "nvim";
      wget = "wget --content-disposition";
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
    # add shortcuts for quick cd in shell
    lib.mapAttrs (name: value: "cd ${value}") config.iynaix.shortcuts;

  iynaix.shell.initExtra = ''
    function md() {
        [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"
    }

    # Suppress output of loud commands you don't want to hear from
    q() {
        "$@" > /dev/null 2>&1;
    }

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

    renamer() {
        pushd ~/projects/personal-graphql
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        yarn renamer
        popd
    }

    # Change cursor with support for inside/outside tmux
    function _set_cursor() {
        if [[ $TMUX = "" ]]; then
          echo -ne $1
        else
          echo -ne "\ePtmux;\e\e$1\e\\"
        fi
    }

    function _set_block_cursor() {
        _set_cursor '\e[2 q'
    }
    function _set_beam_cursor() {
        _set_cursor '\e[6 q'
    }

    # wallust colorscheme
    ${lib.optionalString (config.iynaix.wallust.zsh) "cat ~/.cache/wallust/sequences"}
  '';

  programs = {
    bash.initExtra = cfg.initExtra;
    zsh.initExtra = cfg.initExtra;

    bash.profileExtra = cfg.profileExtra;
    zsh.profileExtra = cfg.profileExtra;
  };
}
