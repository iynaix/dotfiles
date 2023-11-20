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
    runtimeInputs = with pkgs; [git nix-output-monitor];
    text = ''
      cd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      home-manager build --flake ".#''${1:-${host}}" |& nom
      cd -
    '';
  };
  # switch home-manager via nix flake
  hmswitch = pkgs.writeShellApplication {
    name = "hmswitch";
    runtimeInputs = with pkgs; [git nix-output-monitor];
    text = ''
      cd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      home-manager switch --flake ".#''${1:-${host}}" |& nom
      cd -
    '';
  };
  # update home-manager via nix flake
  hmupd8 = pkgs.writeShellApplication {
    name = "hmupd8";
    runtimeInputs = [hmswitch];
    text = ''
      cd ${dots}
      nix flake update
      hmswitch
      cd -
    '';
  };
  # nix garbage collection
  ngc = pkgs.writeShellScriptBin "ngc" ''
    # sudo rm /nix/var/nix/gcroots/auto/*
    if [[ $? -ne 0 ]]; then
      sudo nix-collect-garbage $*
    else
      sudo nix-collect-garbage -d
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
