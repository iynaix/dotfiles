{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      nattr = pkgs.writeShellApplication {
        name = "nattr";
        text = /* sh */ ''
          if [ "$#" -eq 0 ]; then
              echo "No package specified."
              exit 1
          fi

          NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --raw "nixpkgs#$1.outPath"
        '';
      };

      ynattrDrv =
        {
          writeShellApplication,
          fileBrowser ? "yazi",
        }:
        writeShellApplication {
          name = "ynattr";
          runtimeInputs = [ nattr ];
          text = /* sh */ ''
            if [ "$#" -eq 0 ]; then
                echo "No package specified."
                exit 1
            fi

            PKG_DIR=$(nattr "$1")
            # path not found, build it
            if [ ! -e "$PKG_DIR" ]; then
                nix build "nixpkgs#$1" --print-out-paths | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | head -n1
            fi

            ${fileBrowser} "$PKG_DIR"
          '';
        };
    in
    {
      packages = {
        inherit nattr;
        ynattr = pkgs.callPackage ynattrDrv { };

        # creates a file with the symlink contents and renames the original symlink to .orig
        nsymlink = pkgs.writeShellApplication {
          name = "nsymlink";
          text = /* sh */ ''
            if [ "$#" -eq 0 ]; then
                echo "No file(s) specified."
                exit 1
            fi

            for file in "$@"; do
              if [[ "$file" == *.bak ]]; then
                  continue
              fi

              if [ -L "$file" ]; then
                  mv "$file" "$file.bak"
                  cp -L "$file.bak" "$file"
                  chmod +w "$file"

              # regular file, reverse the process
              elif [ -f "$file" ] && [ -L "$file.bak" ]; then
                  mv "$file.bak" "$file"
              fi
            done
          '';
        };

        # tui for searching nix packages or options
        ntv = pkgs.writeShellApplication {
          name = "ntv";
          runtimeInputs = with pkgs; [
            pkgs.fzf
            nix-search-tv
          ];
          # prevent IFD, thanks @Michael-C-Buckley
          text = /* sh */ ''exec "${pkgs.nix-search-tv.src}/nixpkgs.sh" "$@"'';
        };

        nlocate-lib = pkgs.writeShellApplication {
          name = "nlocate-lib";
          runtimeInputs = with pkgs; [
            ripgrep
            nix-index
          ];
          text = /* sh */ ''
            nix-locate -- "lib/$1" | rg -v '^\('
          '';
        };

        # what depends on the given package in the current nixos install?
        ndepends = pkgs.writeShellApplication {
          name = "ndepends";
          text = /* sh */ ''
            if [ "$#" -eq 0 ]; then
                echo "No package(s) provided."
                exit 1
            fi

            # use path if given, otherwise assume it is a package
            get_path() {
                if [[ "$1" == /* ]]; then
                    echo "$1"
                else
                    nix eval --raw "nixpkgs#$1.outPath"
                fi
            }

            parent="/run/current-system"
            child="$(get_path "$1")"

            if [ "$#" -eq 2 ]; then
                parent="$(get_path "$1")"
                child="$(get_path "$2")"
            fi

            # echo then run the command
            cmd="nix why-depends --precise \"$parent\" \"$child\""
            echo "$cmd" >&2
            eval "$cmd"
          '';
        };
      };
    };

  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      inherit (config.custom.constants) dots host;

      # outputs the current nixos generation or sets the  given generation or delta, e.g. -1 as default to boot
      ngeneration = pkgs.writeShellApplicationCompletions {
        name = "ngeneration";
        text = /* sh */ ''
          curr=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')

          if [ "$#" -eq 0 ]; then
            # previous desktop versions: 1196
            prev=${if host == "desktop" then "1196" else "0"}
            if [ "$prev" -gt 0 ]; then
              echo "$curr ($((curr + prev)))"
            else
              echo "$curr"
            fi
          else
            if [[ -f "/nix/var/nix/profiles/system-$1-link/bin/switch-to-configuration" ]]; then
              sudo "/nix/var/nix/profiles/system-$1-link/bin/switch-to-configuration" boot
            else
              target="/nix/var/nix/profiles/system-$((curr + $1))-link/bin/switch-to-configuration"
              if [[ -f "$target" ]]; then
                sudo "$target" boot
              else
                echo "No generation $((curr + $1)) found."
                exit 1
              fi
            fi
          fi
        '';
        completions.bash = /* sh */ ''
          _ngeneration() {
              local profile_dir="/nix/var/nix/profiles"
              local profiles=$(command ls -1 "$profile_dir" | \
                  grep -E '^system-[0-9]+-link$' | \
                  sed -E 's/^system-([0-9]+)-link$/\1/' | \
                  sort -rnu)
              COMPREPLY=($(compgen -W "$profiles" -- "''${COMP_WORDS[COMP_CWORD]}"))
          }

          complete -F _ngeneration ngeneration
        '';
        completions.fish = /* fish */ ''
          function _ngeneration
              set -l profile_dir "/nix/var/nix/profiles"
              command ls -1 "$profile_dir" | \
                string match -r '^system-([0-9]+)-link$' | \
                string replace -r '^system-([0-9]+)-link$' '$1' | \
                sort -ru
          end

          complete --keep-order -c ngeneration -f -a "(_ngeneration)"
        '';
      };

      # nix garbage collection
      ngc = pkgs.writeShellApplication {
        name = "ngc";
        text = /* sh */ ''
          # sudo rm /nix/var/nix/gcroots/auto/*

          rm -f "${dots}/result"

          if [ "$#" -eq 0 ]; then
            sudo nix-collect-garbage -d
          else
            sudo nix-collect-garbage "$@"
          fi
        '';
      };

      # utility for creating a nix repl, allows editing within the repl.nix
      # https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/
      nrepl = pkgs.writeShellApplication {
        name = "nrepl";
        text = /* sh */ ''
          if [[ -f repl.nix ]]; then
            nix repl --arg host '"${host}"' --file ./repl.nix "$@"
          elif [[ -f ./flake.nix ]]; then
            nix repl .
          else
            # use flake repl if not in a nix project
            pushd ${dots} > /dev/null
            nix repl --arg host '"${host}"' --file ./repl.nix "$@"
            popd > /dev/null
          fi
        '';
      };

      # build local package if possible, otherwise build config
      nb = pkgs.writeShellApplication {
        name = "nb";
        runtimeInputs = with pkgs; [ nix-output-monitor ];
        text = /* sh */ ''
          if [ "$#" -eq 0 ]; then
              nom build .
              exit
          fi

          TARGET="''${1/.\#}"

          # using nix build with nixpkgs is very slow as it has to copy nixpkgs to the store
          if [[ $(pwd) =~ /nixpkgs$ ]]; then
              # stop bothering me about untracked files
              untracked_files=$(git ls-files --exclude-standard --others .)
              if [ -n "$untracked_files" ]; then
                  git add "$untracked_files"
              fi

              nix-build -A "$TARGET"
          elif nix eval ".#nixosConfigurations.$TARGET.class" &>/dev/null; then
              nsw --dry --hostname "$TARGET"
          # dotfiles, build local package
          elif [[ $(pwd) =~ /dotfiles$ ]]; then
              # stop bothering me about untracked files
              untracked_files=$(git ls-files --exclude-standard --others .)
              if [ -n "$untracked_files" ]; then
                  git add "$untracked_files"
              fi

              if nix eval ".#$TARGET.name" &>/dev/null; then
                nom build ".#$TARGET"
              else
                nom build ".#nixosConfigurations.${host}.pkgs.$TARGET"
              fi
          # nix repo, build package within flake
          else
              nom build ".#$TARGET"
          fi
        '';
      };

      # test all packages that depend on this change, used for nixpkgs and copied from the PR template
      nb-dependents = pkgs.writeShellApplication {
        name = "nb-dependents";
        runtimeInputs = [ pkgs.nixpkgs-review ];
        text = /* sh */ "nixpkgs-review rev HEAD";
      };

      # build and run local package if possible, otherwise run from nixpkgs
      nr = pkgs.writeShellApplication {
        name = "nr";
        text = /* sh */ ''
          if [ "$#" -eq 0 ]; then
              echo "No package specified."
              exit 1
          fi

          # assume building packages in local nixpkgs if possible
          src="nixpkgs"
          if [[ $(pwd) =~ /nixpkgs$ ]]; then
              src="."
          # dotfiles, custom package exists, build it
          elif [[ $(pwd) =~ /dotfiles$ ]]; then
              if [[ -d "./packages/$1" ]]; then
                src="."
              else
                src="nixpkgs"
              fi
          # flake
          elif [[ -f flake.nix ]]; then
              if nix eval ".#$1" &>/dev/null; then
                src="."
              fi
          fi

          if [ "$src" = "nixpkgs" ]; then
              # don't bother me about unfree
              NIXPKGS_ALLOW_UNFREE=1 nix run --impure "$src#$1" -- "''${@:2}"
          else
              nix run "$src#$1" -- "''${@:2}"
          fi
        '';
      };

      # nixpkgs activity summary
      # from https://github.com/NixOS/nixpkgs/issues/321665
      nixpkgs-commits = pkgs.writeShellApplication {
        name = "nixpkgs-commits";
        runtimeInputs = with pkgs; [
          gh
          jq
        ];
        # See <https://gist.github.com/lorenzleutgeb/239214f1d60b1cf8c79e7b0dc0483deb>.
        text = /* sh */ ''
          # Will exit non-zero if not logged in.
          gh auth status

          if [ $# == 1 ]
          then
              # Pass GitHub login name as commandline argument.
              LOGIN=$1
          else
              # Default to currently logged in user.
              LOGIN=$(gh api user --jq .login)
          fi

          BASE="gh pr list --repo NixOS/nixpkgs --json id --jq length --limit 500"

          MERGED=$($BASE --author "$LOGIN" --state merged)
          REVIEWED=$($BASE --search "reviewed-by:$LOGIN -author:$LOGIN" --state all)

          cat << EOM
          ――――――――――
           - [$MERGED PRs merged](https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+is%3Amerged+author%3A$LOGIN)
           - [$REVIEWED PRs reviewed](https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+reviewed-by%3A$LOGIN+-author%3A$LOGIN)
          EOM
        '';
      };
      # build iso images
      nbuild-iso = pkgs.writeShellApplicationCompletions {
        name = "nbuild-iso";
        runtimeInputs = [ pkgs.nixos-generators ];
        text = /* sh */ ''
          pushd ${dots} > /dev/null
          nix build ".#nixosConfigurations.$1.config.system.build.isoImage"
          popd > /dev/null
        '';
        completions.fish = /* fish */ ''
          function _nbuild_iso
            nix eval --impure --json --expr \
              'with builtins.getFlake (toString ./.); builtins.attrNames nixosConfigurations' | \
              ${lib.getExe pkgs.jq} -r '.[]' | grep iso
            end
            complete -c nbuild-iso -f -a '(_nbuild_iso)'
        '';
      };
      # list all installed packages
      nix-list-packages = pkgs.writeShellApplication {
        name = "nix-list-packages";
        text =
          let
            allPkgs = config.environment.systemPackages |> lib.filter lib.isAttrs |> map (pkg: pkg.name);
          in
          ''sort -ui <<< "${lib.concatLines allPkgs}"'';
      };
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          nix-init' = inputs.wrappers.lib.wrapPackage {
            pkgs = prev;
            package = prev.nix-init;
            flags = {
              "--config" = tomlFormat.generate "config.toml" { maintainers = [ "iynaix" ]; };
            };
          };
          nixpkgs-review' = prev.nixpkgs-review.override { withNom = true; };
        })
      ];

      environment.systemPackages =
        with pkgs;
        [
          nix-init # overlay-ed above
          nixpkgs-review # overlay-ed above
        ]
        ++ [
          ngeneration
          ngc
          nrepl
          nb
          nb-dependents
          nr
          nixpkgs-commits
          nbuild-iso
          nix-list-packages
        ]
        ++ (with pkgs.custom; [
          nattr
          ynattr
          nsymlink
          ntv
          nlocate-lib
          ndepends
        ]);

      custom.persist = {
        home = {
          cache.directories = [
            ".cache/nix-search-tv"
            ".cache/nixpkgs-review"
          ];
        };
      };
    };
}
