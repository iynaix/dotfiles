# create a cross shell config
{
  config,
  host,
  lib,
  pkgs,
  user,
  ...
}: {
  home.shellAliases =
    {
      ":e" = "nvim";
      ":q" = "exit";
      c = "clear";
      btop = "btop --preset 2";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      nano = "nvim";
      nsw = "nswitch";
      open = "xdg-open";
      pj = "openproj";
      py = "python";
      r = "lf";
      t = "eza --tree";
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
    lib.mapAttrs (_: value: "cd ${value}") config.iynaix.shortcuts;

  iynaix.shell.functions = {
    md = {
      bashBody = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
      fishBody = ''if test (count $argv) -eq 1; and mkdir -p -- $argv[1]; and cd -- $argv[1]; end'';
    };
    # create a new devenv environment
    mkdevenv = ''nix flake init --template github:iynaix/dotfiles#$1'';
    # improved which for nix
    where = {
      bashBody = ''readlink -f $(which $1)'';
      fishBody = ''readlink -f (which $argv[1])'';
    };
    # server command, runs a local server
    server = ''${pkgs.python3}/bin/python -m http.server ''${1:-8000}'';
    # cd to project dir
    openproj = {
      bashBody = ''
        cd $HOME/projects
        if [[ $# -eq 1 ]]; then
          cd $1;
        fi
      '';
      bashCompletion = ''
        _openproj() {
            ( cd "$HOME/projects"; printf "%s\n" "$2"* )
        }
        complete -o nospace -C _openproj openproj
      '';
      fishBody = ''
        cd $HOME/projects
        if test (count $argv) -eq 1
          cd $argv[1]
        end
      '';
      fishCompletion = ''find "$HOME/projects/" -maxdepth 1 -type d -exec basename {} \;'';
    };
    renamer = {
      bashBody = ''
        pushd $HOME/projects/personal-graphql
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        yarn renamer
        popd
      '';
      fishBody = ''
        pushd $HOME/projects/personal-graphql
        # activate direnv
        direnv allow; and eval (direnv export fish)
        yarn renamer
        popd
      '';
    };
    # utility for creating a nix repl
    nrepl = {
      bashBody = ''
        if [[ -f repl.nix ]]; then
          nix repl --arg '"${host}"' --file ./repl.nix "$@"
        else
          nix repl "$@"
        fi
      '';
      fishBody = ''
        if test -f repl.nix
          nix repl --file ./repl.nix $argv
        else
          nix repl $argv
        end
      '';
    };
  };

  iynaix.shell.initExtra = ''
    # wallust colorscheme
    ${lib.optionalString (config.iynaix.wallust.shell) "cat /home/${user}/.cache/wallust/sequences"}
  '';
}
