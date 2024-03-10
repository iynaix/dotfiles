{
  config,
  host,
  lib,
  pkgs,
  self,
  user,
  ...
}:
let
  dots = "/persist${config.hm.home.homeDirectory}/projects/dotfiles";
  # outputs the current nixos generation
  nix-current-generation = pkgs.writeShellScriptBin "nix-current-generation" ''
    generations=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
    # add generation number from before desktop format
    echo $(expr $generations + ${if host == "desktop" then "1196" else "0"})
  '';
  # set the current configuration as default to boot
  ndefault = pkgs.writeShellScriptBin "ndefault" ''
    sudo /run/current-system/bin/switch-to-configuration boot
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
    text = ''
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
          nh os switch --nom "''${cleaned_args[@]}" ${dots} -- --option eval-cache false
      else
          nh os switch --nom "$@" --hostname ${host} ${dots} -- --option eval-cache false
      fi

      # only relevant if --dry is passed
      if [[ "$*" != *"--dry"* ]]; then
        echo -e "Switched to Generation \033[1m$(nix-current-generation)\033[0m"
      fi
      cd - > /dev/null
    '';
  };
  # update all nvfetcher overlays and packages
  nv-update = pkgs.writeShellApplication {
    name = "nv-update";
    runtimeInputs = [
      nsw
      pkgs.nvfetcher
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
  # build and push config for laptop
  nsw-remote = pkgs.writeShellApplication {
    name = "nsw-remote";
    text = ''
      cd ${dots}
      sudo nixos-rebuild --target-host "root@''${1:-${user}-laptop}" --flake ".#''${2:-framework}" switch
      cd - > /dev/null
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
      fi

      # custom package exists, build it
      if [[ $(pwd) =~ /dotfiles$ ]] && [[ -d "./packages/$1" ]]; then
          src="."
      fi

      if [ "$#" -eq 1 ]; then
          nix run "$src#$1"
      else
          nix run "$src#$1" -- "''${@:2}"
      fi
    '';
  };
  # build local package if possible, otherwise build config
  nb = pkgs.writeShellApplication {
    name = "nb";
    runtimeInputs = [ nbuild ];
    text = ''
      if [[ $(pwd) =~ /nixpkgs$ ]]; then
          nix build ".#$1"
      elif [[ $(pwd) =~ /dotfiles$ ]] && [[ -d "./packages/$1" ]]; then
          nix build ".#$1"
      else
          nbuild "$@"
      fi
    '';
  };
  # build iso images
  nbuild-iso = pkgs.writeShellApplication {
    name = "nbuild-iso";
    runtimeInputs = [
      nsw
      pkgs.nixos-generators
    ];
    text = ''
      cd ${dots}
      nix build ".#nixosConfigurations.$1.config.system.build.isoImage"
      cd - > /dev/null
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
# create an fhs environment to run downloaded binaries
# https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos
# fhs = let
#   base = pkgs.appimageTools.defaultFhsEnvArgs;
# in
#   pkgs.buildFHSUserEnv (base
#     // {
#       name = "fhs";
#       targetPkgs = pkgs: (
#         # pkgs.buildFHSUserEnv provides only a minimal FHS environment,
#         # lacking many basic packages needed by most software.
#         # Therefore, we need to add them manually.
#         #
#         # pkgs.appimageTools provides basic packages required by most software.
#         (base.targetPkgs pkgs)
#         ++ [
#           pkgs.pkg-config
#           pkgs.ncurses
#           # Feel free to add more packages here if needed.
#         ]
#       );
#       profile = "export FHS=1";
#       runScript = "bash";
#       extraOutputsToInstall = ["dev"];
#     });
{
  # execute shebangs that assume hardcoded shell paths
  services.envfs.enable = true;

  # run unpatched binaries on nixos
  programs.nix-ld.enable = true;

  environment = {
    systemPackages =
      # for nixlang / nixpkgs
      with pkgs;
      [
        nixfmt-rfc-style
        nh
        nil
        nix-init
        nixpkgs-fmt
        nixpkgs-review
        nix-update
      ]
      ++ [
        nix-current-generation
        nix-depends
        ndefault
        nsw
        nvfetcher
        nv-update
        nb
        nr
        nbuild
        nbuild-iso
        upd8
        json2nix
        yaml2nix
        # fhs
      ]
      ++ lib.optionals (host == "desktop") [ nsw-remote ];
  };

  # add symlink of configuration flake to nixos closure
  # https://blog.thalheim.io/2022/12/17/hacking-on-kernel-modules-in-nixos/
  # system.extraSystemBuilderCmds = ''
  #   ln -s ${self} $out/flake
  # '';

  nix = {
    gc = {
      # Automatic garbage collection
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixUnstable;
    registry = {
      nixpkgs-master = {
        from = {
          type = "indirect";
          id = "nixpkgs-master";
        };
        to = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
        };
      };
    };
    settings = {
      auto-optimise-store = true; # Optimise symlinks
      # re-evaluate on every rebuild instead of "cached failure of attribute" error
      eval-cache = false;
      warn-dirty = false;
      # removes ~/.nix-profile and ~/.nix-defexpr
      use-xdg-base-directories = true;

      # use flakes
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake" # allows use of a flake via nix repl ".#desktop"
      ];
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://ghostty.cachix.org"
      ];
      # allow building and pushing of laptop config from desktop
      trusted-users = [ user ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
    };
  };

  # better nixos generation label
  # https://reddit.com/r/NixOS/comments/16t2njf/small_trick_for_people_using_nixos_with_flakes/k2d0sxx/
  system.nixos.label = lib.concatStringsSep "-" (
    (lib.sort (x: y: x < y) config.system.nixos.tags)
    ++ [ "${config.system.nixos.version}.${self.sourceInfo.shortRev or "dirty"}" ]
  );

  hm.custom.persist = {
    home = {
      cache = [
        ".cache/nix"
        ".cache/nixpkgs-review"
      ];
    };
  };
}
