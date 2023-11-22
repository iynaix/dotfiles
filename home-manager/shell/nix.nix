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

      if [ "$#" -eq 0 ]; then
          nh home switch --nom --configuration "${host}"
      else
          nh home switch --nom "$@"
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
  ngc = pkgs.writeShellScriptBin "ngc" ''
    # sudo rm /nix/var/nix/gcroots/auto/*
    if [ "$#" -eq 0 ]; then
      sudo nix-collect-garbage -d
    else
      sudo nix-collect-garbage "$@"
    fi
  '';
in {
  config = lib.mkMerge [
    (lib.mkIf (!isNixOS) {
      home.packages = [
        hmbuild
        hmswitch
        hmupd8
      ];

      home.shellAliases = {
        hsw = "hswitch";
      };
    })
    {
      home.packages = [ngc];
      home.shellAliases = {
        nsh = "nix-shell --command fish -p";
      };
    }
  ];
}
