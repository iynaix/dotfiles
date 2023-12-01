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
      cat = "bat";
      crate = "cargo";
      btop = "btop --preset 0";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      man = "${pkgs.bat-extras.batman}/bin/batman";
      mkdir = "mkdir -p";
      mount = "mount --mkdir";
      nano = "nvim";
      open = "xdg-open";
      pj = "openproj";
      py = "python";
      t = "eza --tree";
      v = "nvim";
      wget = "wget --content-disposition";
      coinfc = "openproj coinfc";

      # cd aliases
      ".." = "cd ..";
      "..." = "cd ../..";
    }
    //
    # add shortcuts for quick cd in shell
    lib.mapAttrs (_: value: "cd ${value}") config.iynaix.shortcuts;

  iynaix.shell.functions = {
    fdnix = {
      bashBody = ''fd "$@" /nix/store'';
      fishBody = ''fd $argv /nix/store'';
    };
    md = {
      bashBody = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
      fishBody = ''if test (count $argv) -eq 1; and mkdir -p -- $argv[1]; and cd -- $argv[1]; end'';
    };
    # create a new devenv environment
    mkdevenv = {
      bashBody = ''nix flake init --template github:iynaix/dotfiles#$1'';
      fishBody = ''nix flake init --template github:iynaix/dotfiles#$argv[1]'';
    };
    # improved which for nix
    where = {
      bashBody = ''readlink -f $(which $1)'';
      fishBody = ''readlink -f (which $argv[1])'';
    };
    lfwhere = {
      bashBody = ''lf $(dirname $(dirname $(readlink -f $(which $1))))'';
      fishBody = ''lf (dirname (dirname (readlink -f (which $argv[1]))))'';
    };
    # server command, runs a local server
    server = {
      bashBody = ''${pkgs.python3}/bin/python -m http.server ''${1:-8000}'';
      fishBody = ''
        if test -n "$1"
          ${pkgs.python3}/bin/python -m http.server "$1"
        else
          ${pkgs.python3}/bin/python -m http.server 8000
        end
      '';
    };
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
        cd $HOME/projects/personal-graphql
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        cargo run --release --bin renamer
        cd - > /dev/null
      '';
      fishBody = ''
        cd $HOME/projects/personal-graphql
        # activate direnv
        direnv allow; and eval (direnv export fish)
        cargo run --release --bin renamer
        cd - > /dev/null
      '';
    };
    # utility for creating a nix repl
    nrepl = {
      bashBody = ''
        if [[ -f repl.nix ]]; then
          nix repl --arg host '"${host}"' --file ./repl.nix "$@"
        else
          nix repl "$@"
        fi
      '';
      fishBody = ''
        if test -f repl.nix
          nix repl --arg host '"${host}"' --file ./repl.nix $argv
        else
          nix repl $argv
        end
      '';
    };
  };
}
