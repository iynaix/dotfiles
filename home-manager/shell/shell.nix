# create a cross shell config
{
  config,
  lib,
  pkgs,
  ...
}:
let
  proj_dir = "/persist${config.home.homeDirectory}/projects";
in
{
  home = {
    shellAliases =
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

    packages = lib.mapAttrsToList (name: content: pkgs.writeShellScriptBin name content) (
      {
        fdnix = ''${lib.getExe pkgs.fd} "$@" /nix/store'';
        md = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
        # improved which for nix
        where = "readlink -f $(which $1)";
        ywhere = "yazi $(dirname $(dirname $(readlink -f $(which $1))))";
        # server command, runs a local server
        server = "${lib.getExe pkgs.python3} -m http.server \${1:-8000}";
        renamer = ''
          cd ${proj_dir}/personal-graphql
          # activate direnv
          direnv allow && eval "$(direnv export bash)"
          cargo run --release --bin renamer
          cd - > /dev/null
        '';
        openproj = ''
          cd ${proj_dir}
          if [[ $# -eq 1 ]]; then
            cd "$1";
          fi
        '';
      }
      // config.custom.shell.functions
    );
  };

  # openproj cannot be implemented as script as it needs to change the directory of the shell
  # bash function and completion for openproj
  programs.bash.initExtra = ''
    function openproj() {
        cd ${proj_dir}
        if [[ $# -eq 1 ]]; then
          cd "$1";
        fi
    }
    _openproj() {
        ( cd ${proj_dir}; printf "%s\n" "$2"* )
    }
    complete -o nospace -C _openproj openproj
  '';

  programs.fish.functions.openproj = ''
    cd ${proj_dir}
    if test (count $argv) -eq 1
      cd $argv[1]
    end
  '';

  # fish completion
  xdg.configFile."fish/completions/openproj.fish".text = ''
    function _openproj
        find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;
    end
    complete --no-files --command openproj --arguments "(_openproj)"
  '';
}
