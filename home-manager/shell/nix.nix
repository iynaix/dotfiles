{
  config,
  host,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  dots = "/persist${config.home.homeDirectory}/projects/dotfiles";
in
{
  home = {
    packages = with pkgs; [
      nh
      nil
      nix-output-monitor
      nixfmt-rfc-style
      nvfetcher
    ];

    shellAliases = {
      nvfetcher-flat = "nvfetcher --build-dir .";
      nsh = "nix-shell --command fish -p";
      nix-update-input = "nix flake lock --update-input";
    };
  };

  custom.shell.packages = rec {
    # outputs the current nixos generation
    nix-current-generation = ''
      GENERATIONS=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
      # add generation number from before desktop format
      echo $(( GENERATIONS + ${if host == "desktop" then "1196" else "0"}))
    '';
    # build flake but don't switch
    nbuild = {
      runtimeInputs = with pkgs; [ custom.shell.nsw ];
      text = ''
        if [ "$#" -eq 0 ]; then
            nsw --dry --hostname "${host}"
        else
            # provide hostname as the first argument
            nsw --dry --hostname "$@"
        fi
      '';
    };
    # switch via nix flake
    nsw = {
      runtimeInputs = with pkgs; [
        git
        nh
        ripgrep
        custom.shell.nix-current-generation
      ];
      text =
        let
          subcmd = if isNixOS then "os" else "home";
          hostFlag = if isNixOS then "hostname" else "configuration";
        in
        ''
          cd ${dots}

          # stop bothering me about untracked files
          untracked_files=$(git ls-files --exclude-standard --others .)
          if [ -n "$untracked_files" ]; then
              git add "$untracked_files"
          fi

          # force switch to always use current host
          if [[ "$*" == *"--${hostFlag}"* ]]; then
              # Replace the word after "--${hostFlag}" with host using parameter expansion
              cleaned_args=("''${@/--${hostFlag} [^[:space:]]*/--${hostFlag} ${host}}")
              nh ${subcmd} switch "''${cleaned_args[@]}" ${dots} -- --option eval-cache false
          else
              nh ${subcmd} switch "$@" --${hostFlag} ${host} ${dots} -- --option eval-cache false
          fi

          ${lib.optionalString isNixOS ''
            # only relevant if --dry is not passed
            if [[ "$*" != *"--dry"* ]]; then
              echo -e "Switched to Generation \033[1m$(nix-current-generation)\033[0m"
            fi
          ''}
          cd - > /dev/null
        '';
    };
    # same as nsw, but do test instead
    nst = nsw // {
      text = lib.replaceStrings [ " switch " ] [ " test " ] nsw.text;
    };
    # update all nvfetcher overlays and packages
    nv-update = {
      runtimeInputs = with pkgs; [
        fd
        nvfetcher
      ];
      text = ''
        cd ${dots}

        # run nvfetcher for overlays
        nvfetcher --config overlays/nvfetcher.toml --build-dir overlays

        # run nvfetcher for packages
        mapfile -t pkg_tomls < <(fd nvfetcher.toml packages)

        for pkg_toml in "''${pkg_tomls[@]}"; do
            pkg_dir=$(dirname "$pkg_toml")
            nvfetcher --config "$pkg_toml" --build-dir "$pkg_dir"
        done
        cd - > /dev/null
      '';
    };
    # update via nix flake
    upd8 = {
      runtimeInputs = with pkgs; [
        nvfetcher
        custom.shell.nsw
        custom.shell.nv-update
      ];
      text = ''
        cd ${dots}
        nix flake update
        nv-update
        nsw "$@"
        cd - > /dev/null
      '';
    };
    # nix garbage collection
    ngc = ''
      # sudo rm /nix/var/nix/gcroots/auto/*
      if [ "$#" -eq 0 ]; then
        sudo nix-collect-garbage -d
      else
        sudo nix-collect-garbage "$@"
      fi
    '';
    # utility for creating a nix repl, allows editing within the repl.nix
    # https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/
    nrepl = ''
      if [[ -f repl.nix ]]; then
        nix repl --arg host '"${host}"' --file ./repl.nix "$@"
      # use flake repl if not in a nix project
      elif [[ $(find . -maxdepth 1 -name "*.nix" | wc -l) -eq 0 ]]; then
        cd ${dots}
        nix repl --arg host '"${host}"' --file ./repl.nix "$@"
        cd - > /dev/null
      else
        nix repl "$@"
      fi
    '';
    # build local package if possible, otherwise build config
    nb = {
      runtimeInputs = with pkgs; [
        nom
        custom.shell.nbuild
      ];
      text = ''
        if [[ $1 == ".#"* ]]; then
            nom build "$@"
        # using nix build with nixpkgs is very slow as it has to copy nixpkgs to the store
        elif [[ $(pwd) =~ /nixpkgs$ ]]; then
            nix-build -A "$1"
        # dotfiles, build local package
        elif [[ $(pwd) =~ /dotfiles$ ]] && [[ -d "./packages/$1" ]]; then
            nom build ".#$1"
        # nix repo, build package within flake
        elif [[ -f flake.nix ]]; then
            nom build ".#$1"
        else
            nbuild "$@"
        fi
      '';
    };
    # build and run local package if possible, otherwise run from nixpkgs
    nr = ''
      if [ "$#" -eq 0 ]; then
          echo "no package specified."
          exit 1
      fi

      # assume building packages in local nixpkgs if possible
      src="nixpkgs"
      if [[ $(pwd) =~ /nixpkgs$ ]]; then
          src="."
      # dotfiles, custom package exists, build it
      elif [[ $(pwd) =~ /dotfiles$ ]] && [[ -d "./packages/$1" ]]; then
          src="."
      # flake
      elif [[ -f flake.nix ]]; then
          src="."
      fi

      if [ "$#" -eq 1 ]; then
          nix run "$src#$1"
      else
          nix run "$src#$1" -- "''${@:2}"
      fi
    '';
    npath = ''
      if [ "$#" -eq 0 ]; then
          echo "no package specified."
          exit 1
      fi

      PKG_DIR=$(nix eval --raw "nixpkgs#$1.outPath")
      if [ -e "$PKG_DIR" ]; then
          echo "$PKG_DIR"
      else
          # path not found, build it
          nix build "nixpkgs#hyprland" --print-out-paths | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | head -n1
      fi
    '';
    ynpath = {
      runtimeInputs = with pkgs; [
        yazi
        custom.shell.npath
      ];
      text = ''yazi "$(npath "$@")"'';
    };
    # what depends on the given package in the current nixos install?
    nix-depends = {
      runtimeInputs = with pkgs; [ custom.shell.npath ];
      text = ''
        if [ "$#" -eq 0 ]; then
            echo "package not found."
            exit 1
        fi

        parent="/run/current-system"
        child="$(npath "$1")"

        if [ "$#" -eq 2 ]; then
          parent="$(npath "$1")"
          child="$(npath "$2")"
        fi

        nix why-depends "$parent" "$child"
      '';
    };
    json2nix = {
      runtimeInputs = with pkgs; [
        hjson
        nixfmt-rfc-style
      ];
      text = ''
        json=$(cat - | hjson -j 2> /dev/null)
        nix eval --expr "lib.strings.fromJSON '''$json'''" | nixfmt -q
      '';
    };
    yaml2nix = {
      runtimeInputs = with pkgs; [
        yq
        nixfmt-rfc-style
      ];
      text = ''
        yaml=$(cat - | yq)
        nix eval --expr "lib.strings.fromJSON '''$yaml'''" | nixfmt -q
      '';
    };
  };

  programs = {
    nix-index.enable = true;
    nixvim.plugins = {
      nix.enable = true;
      lsp.servers.nil_ls.enable = true;
    };
  };

  custom.persist = {
    home = {
      cache = [ ".cache/nix-index" ];
    };
  };
}
