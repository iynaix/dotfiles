{
  flake.nixosModules.core =
    {
      config,
      dots,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        attrValues
        functionArgs
        hiPrio
        intersectAttrs
        isDerivation
        isString
        length
        mapAttrs
        mkOption
        optional
        ;
      inherit (lib.types)
        attrs
        attrsOf
        oneOf
        package
        str
        ;
      proj_dir = "/persist${config.hj.directory}/projects";
      # writeShellApplication with support for completions
      writeShellApplicationCompletions =
        {
          name,
          bashCompletion ? null,
          zshCompletion ? null,
          fishCompletion ? null,
          ...
        }@shellArgs:
        let
          inherit (pkgs) writeShellApplication writeTextFile symlinkJoin;
          # get the needed arguments for writeShellApplication
          app = writeShellApplication (intersectAttrs (functionArgs writeShellApplication) shellArgs);
          completions =
            optional (bashCompletion != null) (writeTextFile {
              name = "${name}.bash";
              destination = "/share/bash-completion/completions/${name}.bash";
              text = bashCompletion;
            })
            ++ optional (zshCompletion != null) (writeTextFile {
              name = "${name}.zsh";
              destination = "/share/zsh/site-functions/_${name}";
              text = zshCompletion;
            })
            ++ optional (fishCompletion != null) (writeTextFile {
              name = "${name}.fish";
              destination = "/share/fish/vendor_completions.d/${name}.fish";
              text = fishCompletion;
            });
        in
        if length completions == 0 then
          app
        else
          symlinkJoin {
            inherit name;
            inherit (app) meta;
            paths = [ app ] ++ completions;
          };
    in
    {
      options.custom = {
        shell = {
          packages = mkOption {
            type = attrsOf (oneOf [
              str
              attrs
              package
            ]);
            # produces an attrset shell package with completions from either a string / writeShellApplication attrset / package
            apply = mapAttrs (
              name: value:
              if isString value then
                pkgs.writeShellApplication {
                  inherit name;
                  text = value;
                }
              # packages
              else if isDerivation value then
                value
              # attrs to pass to writeShellApplication
              else
                writeShellApplicationCompletions (value // { inherit name; })
            );
            default = { };
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

      config =
        let
          homeDir = config.hj.directory;
          xdg-user-dirs = {
            # xdg user dirs
            XDG_DESKTOP_DIR = "${homeDir}/Desktop";
            XDG_DOCUMENTS_DIR = "${homeDir}/Documents";
            XDG_DOWNLOAD_DIR = "${homeDir}/Downloads";
            XDG_MUSIC_DIR = "${homeDir}/Music";
            XDG_PICTURES_DIR = "${homeDir}/Pictures";
            XDG_PUBLICSHARE_DIR = "${homeDir}/Public";
            XDG_TEMPLATES_DIR = "${homeDir}/Templates";
            XDG_VIDEOS_DIR = "${homeDir}/Videos";
          };
        in
        {
          environment = {
            shellAliases = {
              ":e" = "nvim";
              ":q" = "exit";
              ":wq" = "exit";
              c = "clear";
              cat = "bat";
              ccat = "command cat";
              cp = "cp -ri";
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
              sl = "ls";
              w = "watch -cn1 -x cat";
              coinfc = "pj coinfc";

              # cd aliases
              ".." = "cd ..";
              "..." = "cd ../..";
            };

            systemPackages =
              with pkgs;
              [
                bonk # mkdir and touch in one
                curl
                # dysk # better disk info
                ets # add timestamp to beginning of each line
                fd # better find
                fx # terminal json viewer and processor
                gzip
                htop
                jq
                killall
                procs # better ps
                (hiPrio procps) # for uptime
                sd # better sed
                trash-cli
                ugrep # grep, with boolean query patterns, e.g. ug --files -e "A" --and "B"
                xdg-utils
              ]
              # add custom user created shell packages
              ++ (attrValues config.custom.shell.packages);

            variables = {
              TERMINAL = "ghostty";
              EDITOR = "nvim";
              VISUAL = "nvim";
              NIXPKGS_ALLOW_UNFREE = "1";
              # xdg
              XDG_CACHE_HOME = config.hj.xdg.cache.directory;
              XDG_CONFIG_HOME = config.hj.xdg.config.directory;
              XDG_DATA_HOME = config.hj.xdg.data.directory;
              XDG_STATE_HOME = config.hj.xdg.state.directory;
            }
            // xdg-user-dirs;
          };

          # follow xdg user dirs spec, see hm for original implementation
          # https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg-user-dirs.nix
          hj.xdg.config.files = {
            "user-dirs.conf".text = "enabled=False";
            "user-dirs.dirs".text =
              let
                # For some reason, these need to be wrapped with quotes to be valid.
                wrapped = lib.mapAttrs (_: value: ''"${value}"'') xdg-user-dirs;
              in
              lib.generators.toKeyValue { } wrapped;
          };

          nixpkgs = {
            # add custom user created shell packages to pkgs.custom.shell
            overlays = [
              (_: prev: {
                custom = (prev.custom or { }) // {
                  shell = config.custom.shell.packages;
                };
              })
            ];
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
              nwhich = {
                text = # sh
                  ''readlink -f "$(which "$1")"'';
              }
              // binariesCompletion "nwhich";
              cnwhich = {
                text = # sh
                  ''cat "$(nwhich "$1")"'';
              }
              // binariesCompletion "cnwhich";
              ynwhich = {
                runtimeInputs = with pkgs; [
                  custom.shell.nwhich
                ];
                text = # sh
                  ''yazi "$(dirname "$(dirname "$(nwhich "$1")")")"'';
              }
              // binariesCompletion "ynwhich";
              # uniq but maintain original order
              uuniq = "awk '!x[$0]++'";
            };

          # pj cannot be implemented as script as it needs to change the directory of the shell
          programs = {
            bash.shellInit = # sh
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

            fish.shellInit = # fish
              ''
                function pj
                  cd ${proj_dir}
                  if test (count $argv) -eq 1
                    cd $argv[1]
                  end
                end

                function _pj
                    find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;
                end
                complete -c pj -f -a "(_pj)"
              '';
          };
        };
    };
}
