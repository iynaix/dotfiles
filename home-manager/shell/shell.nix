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
    shellAliases = {
      ":e" = "nvim";
      ":q" = "exit";
      ":wq" = "exit";
      c = "clear";
      cat = "bat";
      ccat = "command cat";
      crate = "cargo";
      dots = "cd ${proj_dir}/dotfiles";
      isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
      man = lib.getExe' pkgs.bat-extras.batman "batman";
      mime = "xdg-mime query filetype";
      mkdir = "mkdir -p";
      mount = "mount --mkdir";
      open = "xdg-open";
      py = "python";
      coinfc = "pj coinfc";

      # cd aliases
      ".." = "cd ..";
      "..." = "cd ../..";
    };
  };

  custom.shell.packages =
    let
      binariesCompletion = binaryName: {
        bashCompletion = ''
          _complete_path_binaries()
          {
              local cur prev words cword
              _init_completion || return

              local IFS=:
              local binaries=()
              for path in $PATH; do
                  for bin in "$path"/*; do
                      if [[ -x "$bin" && -f "$bin" ]]; then
                          binaries+=("$(basename "$bin")")
                      fi
                  done
              done

              COMPREPLY=($(compgen -W "''${binaries[*]}" -- "$cur"))
          }

          complete -F _complete_path_binaries ${binaryName}
        '';
        fishCompletion = ''
          function __complete_path_binaries
              for path in $PATH
                  for bin in $path/*
                      if test -x $bin -a -f $bin
                          set -l bin_name (basename $bin)
                          echo $bin_name
                      end
                  end
              end
          end

          complete -c ${binaryName} -f -a "(__complete_path_binaries)"
        '';
      };
    in
    {
      fdnix = {
        runtimeInputs = [ pkgs.fd ];
        text = ''fd "$@" /nix/store'';
      };
      md = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
      # improved which for nix
      where = {
        text = ''readlink -f "$(which "$1")"'';
      } // binariesCompletion "where";
      cwhere = {
        text = ''cat "$(where "$1")"'';
      } // binariesCompletion "cwhere";
      ywhere = {
        runtimeInputs = with pkgs; [
          yazi
          custom.shell.where
        ];
        text = ''yazi "$(dirname "$(dirname "$(where "$1")")")"'';
      } // binariesCompletion "ywhere";
    };

  # pj cannot be implemented as script as it needs to change the directory of the shell
  # bash function and completion for pj
  programs.bash.initExtra = ''
    function pj() {
        cd ${proj_dir}
        if [[ $# -eq 1 ]]; then
          cd "$1";
        fi
    }
    _pj() {
        ( cd ${proj_dir}; printf "%s\n" "$2"* )
    }
    complete -o nospace -C _pj pj
  '';

  programs.fish.functions.pj = ''
    cd ${proj_dir}
    if test (count $argv) -eq 1
      cd $argv[1]
    end
  '';

  # fish completion
  xdg.configFile."fish/completions/pj.fish".text = ''
    function _pj
        find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;
    end
    complete -c pj -f -a "(_pj)"
  '';
}
