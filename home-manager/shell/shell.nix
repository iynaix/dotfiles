# create a cross shell config
{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  proj_dir = "/persist${config.home.homeDirectory}/projects";
in
{
  home.shellAliases =
    {
      ":e" = "nvim";
      ":q" = "exit";
      c = "clear";
      cat = "bat";
      ccat = "command cat";
      crate = "cargo";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      man = lib.getExe' pkgs.bat-extras.batman "batman";
      mime = "xdg-mime query filetype";
      mkdir = "mkdir -p";
      mount = "mount --mkdir";
      open = "xdg-open";
      pj = "openproj";
      py = "python";
      coinfc = "openproj coinfc";

      # cd aliases
      ".." = "cd ..";
      "..." = "cd ../..";
    }
    //
    # add shortcuts for quick cd in shell
    lib.mapAttrs (_: value: "cd ${value}") config.custom.shortcuts;

  custom.shell.functions = {
    fdnix = {
      bashBody = ''fd "$@" /nix/store'';
      fishBody = "fd $argv /nix/store";
    };
    md = {
      bashBody = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
      fishBody = "if test (count $argv) -eq 1; and mkdir -p -- $argv[1]; and cd -- $argv[1]; end";
    };
    # improved which for nix
    where = {
      bashBody = "readlink -f $(which $1)";
      fishBody = "readlink -f (which $argv[1])";
    };
    ywhere = {
      bashBody = "yazi $(dirname $(dirname $(readlink -f $(which $1))))";
      fishBody = "yazi (dirname (dirname (readlink -f (which $argv[1]))))";
    };
    # server command, runs a local server
    server = {
      bashBody = "${lib.getExe pkgs.python3} -m http.server \${1:-8000}";
      fishBody = ''
        if test -n "$1"
          ${lib.getExe pkgs.python3} -m http.server "$1"
        else
          ${lib.getExe pkgs.python3} -m http.server 8000
        end
      '';
    };
    # cd to project dir
    openproj = {
      bashBody = ''
        cd ${proj_dir}
        if [[ $# -eq 1 ]]; then
          cd $1;
        fi
      '';
      bashCompletion = ''
        _openproj() {
            ( cd ${proj_dir}; printf "%s\n" "$2"* )
        }
        complete -o nospace -C _openproj openproj
      '';
      fishBody = ''
        cd ${proj_dir}
        if test (count $argv) -eq 1
          cd $argv[1]
        end
      '';
      fishCompletion = ''find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;'';
    };
    renamer = {
      bashBody = ''
        cd ${proj_dir}/personal-graphql
        # activate direnv
        direnv allow && eval "$(direnv export bash)"
        cargo run --release --bin renamer
        cd - > /dev/null
      '';
      fishBody = ''
        cd ${proj_dir}/personal-graphql
        # activate direnv
        direnv allow; and eval (direnv export fish)
        cargo run --release --bin renamer
        cd - > /dev/null
      '';
    };
    # utility for creating a nix repl, allows editing within the repl.nix
    # https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/
    nrepl = {
      bashBody = ''
        if [[ -f repl.nix ]]; then
          nix repl --arg host '"${host}"' --file ./repl.nix "$@"
        # use flake repl if not in a nix project
        elif [[ $(find . -maxdepth 1 -name "*.nix" | wc -l) -eq 0 ]]; then
          cd ${proj_dir}/dotfiles
          nix repl --arg host '"${host}"' --file ./repl.nix "$@"
          cd - > /dev/null
        else
          nix repl "$@"
        fi
      '';
      fishBody = ''
        if test -f repl.nix
            nix repl --arg host '"${host}"' --file ./repl.nix $argv
        # use flake repl if not in a nix project
        else if test (find . -maxdepth 1 -name "*.nix" | wc -l) -eq 0
          cd ${proj_dir}/dotfiles
          nix repl --arg host '"${host}"' --file ./repl.nix $argv
          cd - > /dev/null
        else
          nix repl $argv
        end
      '';
    };
  };
}
