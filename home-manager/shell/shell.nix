{
  config,
  dots,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  proj_dir = "/persist${config.home.homeDirectory}/projects";
in
{
  options.custom = {
    shell = {
      packages = mkOption {
        type =
          with types;
          attrsOf (oneOf [
            str
            attrs
            package
          ]);
        default = { };
        apply = lib.custom.mkShellPackages;
        description = ''
          Attrset of shell packages to install and add to pkgs.custom overlay (for compatibility across multiple shells).
          Both string and attr values will be passed as arguments to writeShellApplicationCompletions
        '';
        example = ''
          shell.packages = {
            myPackage1 = "echo 'Hello, World!'";
            myPackage2 = {
              runtimeInputs = [ pkgs.hello ];
              text = "hello --greeting 'Hi'";
            };
          }
        '';
      };
    };
  };

  config = {
    home = {
      shellAliases = {
        ":e" = "nvim";
        ":q" = "exit";
        ":wq" = "exit";
        c = "clear";
        cat = "bat";
        ccat = "command cat";
        crate = "cargo";
        dots = "cd ${dots}";
        isodate = ''date -u "+%Y-%m-%dT%H:%M:%SZ"'';
        man = "batman";
        mime = "xdg-mime query filetype";
        mkdir = "mkdir -p";
        mount = "mount --mkdir";
        np = "cd ${proj_dir}/nixpkgs";
        open = "xdg-open";
        py = "python";
        w = "watch -cn1 -x cat";
        coinfc = "pj coinfc";

        # cd aliases
        ".." = "cd ..";
        "..." = "cd ../..";
      };
    };

    custom.shell.packages =
      let
        binariesCompletion = binaryName: {
          bashCompletion = # sh
            ''
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
          fishCompletion = # fish
            ''
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
          text = # sh
            ''fd "$@" /nix/store'';
        };
        md = # sh
          ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
        # improved which for nix
        where = {
          text = # sh
            ''readlink -f "$(which "$1")"'';
        } // binariesCompletion "where";
        cwhere = {
          text = # sh
            ''cat "$(where "$1")"'';
        } // binariesCompletion "cwhere";
        ywhere = {
          runtimeInputs = with pkgs; [
            yazi
            custom.shell.where
          ];
          text = # sh
            ''yazi "$(dirname "$(dirname "$(where "$1")")")"'';
        } // binariesCompletion "ywhere";
        # uniq but maintain original order
        uuniq = "awk '!x[$0]++'";
      };

    # pj cannot be implemented as script as it needs to change the directory of the shell
    # bash function and completion for pj
    programs.bash.initExtra = # sh
      ''
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

    programs.fish.functions.pj = # fish
      ''
        cd ${proj_dir}
        if test (count $argv) -eq 1
          cd $argv[1]
        end
      '';

    # fish completion
    xdg.configFile."fish/completions/pj.fish".text = # sh
      ''
        function _pj
            find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;
        end
        complete -c pj -f -a "(_pj)"
      '';
  };
}
