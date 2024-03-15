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
  # home manager utilities
  # build flake but don't switch
  hmbuild = pkgs.writeShellApplication {
    name = "hmbuild";
    runtimeInputs = [ hmswitch ];
    text = ''
      if [ "$#" -eq 0 ]; then
          hmswitch --dry --configuration "${host}"
      else
          # provide hostname as the first argument
          hmswitch --dry --hostname "$@"
      fi
    '';
  };
  # switch home-manager via nix flake
  hmswitch = pkgs.writeShellApplication {
    name = "hmswitch";
    runtimeInputs = with pkgs; [
      git
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
          nh home switch "''${cleaned_args[@]}" ${dots} -- --option eval-cache false
      else
          nh home switch "$@" --hostname ${host} ${dots} -- --option eval-cache false
      fi

      cd - > /dev/null
    '';
  };
  # update home-manager via nix flake
  hmupd8 = pkgs.writeShellApplication {
    name = "hmupd8";
    runtimeInputs = [ hmswitch ];
    text = ''
      cd ${dots}
      nix flake update
      hmswitch "$@"
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
in
lib.mkMerge [
  (lib.mkIf (!isNixOS) {
    home = {
      packages = [
        hmbuild
        hmswitch
        hmupd8
        pkgs.nh # nh is installed by nixos config anyway
      ];

      shellAliases = {
        hsw = "hswitch";
      };
    };
  })
  {
    home = {
      packages = [
        ngc
        nrepl
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
]
