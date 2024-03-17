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
  # outputs the current nixos generation
  nix-current-generation = pkgs.writeShellScriptBin "nix-current-generation" ''
    generations=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
    # add generation number from before desktop format
    echo $(expr $generations + ${if host == "desktop" then "1196" else "0"})
  '';
  # build flake but don't switch
  nbuild = pkgs.writeShellApplication {
    name = "nbuild";
    runtimeInputs = [ nsw ];
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
  nsw = pkgs.writeShellApplication {
    name = "nsw";
    runtimeInputs = with pkgs; [
      git
      nix-current-generation
      nh
    ];
    text =
      let
        subcmd = if isNixOS then "os" else "home";
      in
      ''
        cd ${dots}

        # stop bothering me about untracked files
        untracked_files=$(git ls-files --exclude-standard --others .)
        if [ -n "$untracked_files" ]; then
            git add "$untracked_files"
        fi

        # force switch to always use current host
        if [[ "$*" == *"--hostname"* ]]; then
            # Replace the word after "--hostname" with host using parameter expansion
            cleaned_args=("''${@/--hostname [^[:space:]]*/--hostname ${host}}")
            nh ${subcmd} switch "''${cleaned_args[@]}" ${dots} -- --option eval-cache false
        else
            nh ${subcmd} switch "$@" --hostname ${host} ${dots} -- --option eval-cache false
        fi

        ${lib.optionalString isNixOS ''
          # only relevant if --dry is passed
          if [[ "$*" != *"--dry"* ]]; then
            echo -e "Switched to Generation \033[1m$(nix-current-generation)\033[0m"
          fi
        ''}
        cd - > /dev/null
      '';
  };
  # update all nvfetcher overlays and packages
  nv-update = pkgs.writeShellApplication {
    name = "nv-update";
    runtimeInputs = [ pkgs.nvfetcher ];
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
  upd8 = pkgs.writeShellApplication {
    name = "upd8";
    runtimeInputs = [
      nsw
      pkgs.nvfetcher
      nv-update
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
  ngc = pkgs.writeShellApplication {
    name = "ngc";
    text = ''
      # sudo rm /nix/var/nix/gcroots/auto/*
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
    text = ''
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
  };
  # build local package if possible, otherwise build config
  nb = pkgs.writeShellApplication {
    name = "nb";
    runtimeInputs = [ nbuild ];
    text = ''
      if [[ $1 == ".#"* ]]; then
          nix build "$@"
      # using nix build with nixpkgs is very slow as it has to copy nixpkgs to the store
      elif [[ $(pwd) =~ /nixpkgs$ ]]; then
          nix-build -A "$1"
      # dotfiles, build local package
      elif [[ $(pwd) =~ /dotfiles$ ]] && [[ -d "./packages/$1" ]]; then
          nix build ".#$1"
      # nix repo, build package within flake
      elif [[ -f flake.nix ]]; then
          nix build ".#$1"
      else
          nbuild "$@"
      fi
    '';
  };
  # build and run local package if possible, otherwise run from nixpkgs
  nr = pkgs.writeShellApplication {
    name = "nr";
    text = ''
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
  };
  # what depends on the given package in the current nixos install?
  nix-depends = pkgs.writeShellApplication {
    name = "nix-depends";
    text = ''
      nix why-depends "/run/current-system" "$(nix eval --raw "nixpkgs#$1.outPath")"
    '';
  };
  json2nix = pkgs.writeShellApplication {
    name = "json2nix";
    runtimeInputs = with pkgs; [
      hjson
      nixfmt-rfc-style
    ];
    text = ''
      json=$(cat - | hjson -j 2> /dev/null)
      nix eval --expr "lib.strings.fromJSON '''$json'''" | nixfmt -q
    '';
  };
  yaml2nix = pkgs.writeShellApplication {
    name = "yaml2nix";
    runtimeInputs = with pkgs; [
      yq
      nixfmt-rfc-style
    ];
    text = ''
      yaml=$(cat - | yq)
      nix eval --expr "lib.strings.fromJSON '''$yaml'''" | nixfmt -q
    '';
  };
in
{
  home = {
    packages =
      with pkgs;
      [
        nh
        nil
        nix-output-monitor
        nixfmt-rfc-style
        nvfetcher
      ]
      ++ [
        nix-current-generation
        nbuild
        nsw
        nv-update
        upd8
        ngc
        nrepl
        nb
        nr
        nix-depends
        json2nix
        yaml2nix
      ];

    shellAliases = {
      nsh = "nix-shell --command fish -p";
      nix-update-input = "nix flake lock --update-input";
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
