{
  config,
  dots,
  host,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionalAttrs;
  nixpkgs-review = pkgs.nixpkgs-review.override { withNom = true; };
in
{
  home = {
    packages = with pkgs; [
      nh
      nixd
      nix-output-monitor
      nix-tree
      nixfmt-rfc-style
      nixpkgs-review
      nvfetcher
    ];

    shellAliases = {
      nfl = "nix flake lock";
      nfu = "nix flake update";
      nsh = "nix-shell --command fish -p";
      nshp = "nix-shell --pure --command fish -p";
    };
  };

  custom.shell.packages =
    {
      # outputs the current nixos generation or sets the  given generation or delta, e.g. -1 as default to boot
      ngeneration = {
        text = # sh
          ''
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
        bashCompletion = # sh
          ''
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
        fishCompletion = # fish
          ''
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
      # nixos-rebuild switch, use different package for home-manager standalone
      nsw =
        if isNixOS then
          pkgs.custom.nsw.override {
            inherit dots host;
            name = "nsw";
          }
        else
          pkgs.custom.hsw.override {
            inherit dots host;
            name = "nsw";
          };
      # update all nvfetcher overlays and packages
      nv-update = {
        runtimeInputs = with pkgs; [
          fd
          nvfetcher
        ];
        text = # sh
          ''
            pushd ${dots} > /dev/null

            if [ "$#" -eq 0 ]; then
              # run nvfetcher for overlays
              nvfetcher --keep-old --config overlays/nvfetcher.toml --build-dir overlays

              # run nvfetcher for packages
              mapfile -t pkg_tomls < <(fd nvfetcher.toml packages)

              for pkg_toml in "''${pkg_tomls[@]}"; do
                  pkg_dir=$(dirname "$pkg_toml")
                  nvfetcher --keep-old --config "$pkg_toml" --build-dir "$pkg_dir"
              done
            else
              # special case
              if [ "$1" = "main" ]; then
                nvfetcher --keep-old --config overlays/nvfetcher.toml --build-dir overlays
              elif  [[ -d "./packages/$1" ]]; then
                # run nvfetcher for just the package
                nvfetcher --keep-old --config "./packages/$1/nvfetcher.toml" --build-dir "./packages/$1"
              else
                # run nvfetcher for overlays
                nvfetcher --keep-old --config overlays/nvfetcher.toml --build-dir overlays
              fi
              exit
            fi
            popd > /dev/null
          '';
        bashCompletion = # sh
          ''
            _nv_update() {
                local cur="''${COMP_WORDS[COMP_CWORD]}"
                local options=("main")

                while IFS= read -r -d ''' dir; do
                    if [[ -f "$dir/generated.nix" ]]; then
                        options+=("$(basename "$dir")")
                    fi
                done < <(find "${dots}/packages" -mindepth 1 -maxdepth 1 -type d -print0)

                COMPREPLY=($(compgen -W "''${options[*]}" -- "$cur"))
            }

            complete -F _nv_update nv-update
          '';
        fishCompletion = # fish
          ''
            function _nv_update
                # "root" special case
                echo "main"

                for dir in "${dots}/packages/*/"
                    set -l dir (string trim -r -c / $dir)
                    if test -f "$dir/generated.nix"
                        echo (basename $dir)
                    end
                end
            end

            complete -c nv-update -f -a '(_nv_update)'
          '';
      };
      # update via nix flake
      upd8 = {
        runtimeInputs = with pkgs; [
          nvfetcher
          custom.shell.nsw
          custom.shell.nv-update
        ];
        text = # sh
          ''
            pushd ${dots} > /dev/null
            nix flake update
            nv-update
            nsw "$@"
            popd > /dev/null
          '';
      };
      # nix garbage collection
      ngc = # sh
        ''
          # sudo rm /nix/var/nix/gcroots/auto/*

          rm -f "${dots}/result"

          if [ "$#" -eq 0 ]; then
            sudo nix-collect-garbage -d
          else
            sudo nix-collect-garbage "$@"
          fi
        '';
      # utility for creating a nix repl, allows editing within the repl.nix
      # https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/
      nrepl = # sh
        ''
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
      # build local package if possible, otherwise build config
      nb = {
        runtimeInputs = with pkgs; [ nix-output-monitor ];
        text = # sh
          ''
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
      nb-dependents = {
        runtimeInputs = [ nixpkgs-review ];
        text = # sh
          ''nixpkgs-review rev HEAD'';
      };
      # build and run local package if possible, otherwise run from nixpkgs
      nr = # sh
        ''
          if [ "$#" -eq 0 ]; then
              echo "no package specified."
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
      # creates a file with the symlink contents and renames the original symlink to .orig
      nsymlink = # sh
        ''
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
      nattr = # sh
        ''
          if [ "$#" -eq 0 ]; then
              echo "no package specified."
              exit 1
          fi

          NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --raw "nixpkgs#$1.outPath"
        '';
      ynattr = {
        runtimeInputs = with pkgs; [
          yazi
          custom.shell.nattr
        ];
        text = # sh
          ''
            if [ "$#" -eq 0 ]; then
                echo "no package specified."
                exit 1
            fi

            PKG_DIR=$(nattr "$1")
            # path not found, build it
            if [ ! -e "$PKG_DIR" ]; then
                nix build "nixpkgs#$1" --print-out-paths | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | head -n1
            fi

            yazi "$PKG_DIR"
          '';
      };
      # tui for searching nix packages or options
      nrg = {
        runtimeInputs = with pkgs; [
          config.programs.fzf.package
          nix-search-tv
        ];
        text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
      };
      # what depends on the given package in the current nixos install?
      ndepends = # sh
        ''
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
          cmd="nix why-depends --all --precise \"$parent\" \"$child\""
          echo "$cmd" >&2
          eval "$cmd"
        '';
      json2nix = {
        runtimeInputs = with pkgs; [
          hjson
          nixfmt-rfc-style
        ];
        text = # sh
          ''
            json=$(cat - | hjson -j 2> /dev/null)
            nix eval --expr "fromJSON '''$json'''" | nixfmt -q
          '';
      };
      yaml2nix = {
        runtimeInputs = with pkgs; [
          yq
          nixfmt-rfc-style
        ];
        text = # sh
          ''
            yaml=$(cat - | yq)
            nix eval --expr "fromJSON '''$yaml'''" | nixfmt -q
          '';
      };
    }
    # nh home doesnt have boot or test
    // optionalAttrs isNixOS {
      # nixos-rebuild boot
      nsb = {
        runtimeInputs = [ pkgs.custom.shell.nsw ];
        text = # sh
          ''nsw boot "$@"'';
      };
      # nixos-rebuild test
      nst = {
        runtimeInputs = [ pkgs.custom.shell.nsw ];
        text = # sh
          ''nsw test "$@"'';
      };
    };

  programs.nix-index.enable = true;

  custom.persist = {
    home = {
      cache.directories = [
        ".cache/nix-index"
        ".cache/nix-search-tv"
      ];
    };
  };
}
