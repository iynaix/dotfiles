{
  host,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}: let
  dots = "/persist/home/${user}/projects/dotfiles";
  # home manager utilities
  # build flake but don't switch
  hmbuild = pkgs.writeShellApplication {
    name = "hmbuild";
    runtimeInputs = [hmswitch];
    text = ''
      if [ "$#" -eq 0 ]; then
          hmswitch --dry --configuration "${host}"
      else
          # provide hostname as the first argument
          hmswitch --dry --hostname "$@"
      fi
    '';
  };
  # switch home-manager via nix flake (note you have to pass --hostname to switch to a different host)
  hmswitch = pkgs.writeShellApplication {
    name = "hmswitch";
    runtimeInputs = with pkgs; [git nh];
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
          nh home switch --nom "''${cleaned_args[@]}" -- --option eval-cache false
      else
          nh home switch --nom "$@" --hostname ${host} -- --option eval-cache false
      fi

      cd - > /dev/null
    '';
  };
  # update home-manager via nix flake
  hmupd8 = pkgs.writeShellApplication {
    name = "hmupd8";
    runtimeInputs = [hmswitch];
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
  nr = pkgs.writeShellApplication {
    name = "nr";
    runtimeInputs = [pkgs.nixFlakes];
    text = ''
      if [ "$#" -eq 0 ]; then
          echo "no package specified."
          exit 1
      elif [ "$#" -eq 1 ]; then
          nix run nixpkgs#"$1"
      else
          nix run nixpkgs#"$1" -- "''${@:2}"
      fi
    '';
  };
in {
  config = lib.mkMerge [
    (lib.mkIf (!isNixOS) {
      home = {
        packages = [
          hmbuild
          hmswitch
          hmupd8
          pkgs.nh # nh is installed by nixos anyway
        ];

        shellAliases = {
          hsw = "hswitch";
        };
      };
    })
    {
      home = {
        packages = [ngc nr];
        shellAliases = {
          nsh = "nix-shell --command fish -p";
        };
      };

      programs = {
        nix-index.enable = true;
        nixvim.plugins = {
          nix.enable = true;
          lsp.servers.nil_ls.enable = true;
        };
      };

      iynaix.persist = {
        cache = [
          ".cache/nix-index"
        ];
      };
    }
  ];
}
