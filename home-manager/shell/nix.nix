{
  pkgs,
  host,
  user,
  ...
}: let
  dots = "/home/${user}/projects/dotfiles";
  # home manager utilities
  # build flake but don't switch
  hmbuild = pkgs.writeShellApplication {
    name = "hmbuild";
    runtimeInputs = with pkgs; [git nix-output-monitor];
    text = ''
      pushd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      home-manager build --flake ".#''${1:-${host}}" |& nom
      popd
    '';
  };
  # switch home-manager via nix flake
  hmswitch = pkgs.writeShellApplication {
    name = "hmswitch";
    runtimeInputs = with pkgs; [git nix-output-monitor];
    text = ''
      pushd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      home-manager switch --flake ".#''${1:-${host}}" |& nom
      popd
    '';
  };
  # update home-manager via nix flake
  hmupd8 = pkgs.writeShellApplication {
    name = "hmupd8";
    runtimeInputs = [hmswitch];
    text = ''
      pushd ${dots}
      nix flake update
      hmswitch
      popd
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
  home.packages = [
    hmbuild
    hmswitch
    hmupd8
    ngc
  ];

  home.shellAliases = {
    hsw = "hswitch";
    nsh = "nix-shell --command fish -p";
  };
}
