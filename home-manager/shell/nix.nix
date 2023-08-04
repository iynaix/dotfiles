{
  pkgs,
  host,
  isNixOS,
  lib,
  ...
}: let
  # outputs the current nixos generation
  nix-current-generation = pkgs.writeShellScriptBin "nix-current-generation" ''
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'
  '';
  # set the current configuration as default to boot
  ndefault = pkgs.writeShellScriptBin "ndefault" ''
    sudo /run/current-system/bin/switch-to-configuration boot
  '';
  # build flake but don't switch
  nbuild = pkgs.writeShellScriptBin "nbuild" ''
    pushd ~/projects/dotfiles
    sudo nixos-rebuild build --flake ".#''${1:-${host}}"
    popd
  '';
  # switch via nix flake
  nswitch = pkgs.writeShellApplication {
    name = "nswitch";
    runtimeInputs = [nix-current-generation];
    text = ''
      pushd ~/projects/dotfiles
      sudo nixos-rebuild switch --flake ".#''${1:-${host}}" && \
      echo -e "Switched to Generation \033[1m$(nix-current-generation)\033[0m"
      popd
    '';
  };
  # update via nix flake
  upd8 = pkgs.writeShellApplication {
    name = "upd8";
    runtimeInputs = [nswitch];
    text = ''
      pushd ~/projects/dotfiles
      nix flake update
      nswitch
      popd
    '';
  };
  # home manager utilities
  # build flake but don't switch
  hmbuild = pkgs.writeShellScriptBin "hmbuild" ''
    pushd ~/projects/dotfiles
    home-manager build --flake ".#''${1:-${host}}"
    popd
  '';
  # switch home-manager via nix flake
  hmswitch = pkgs.writeShellScriptBin "hmswitch" ''
    pushd ~/projects/dotfiles
    home-manager switch --flake ".#''${1:-${host}}"
    popd
  '';
  # update home-manager via nix flake
  hmupd8 = pkgs.writeShellApplication {
    name = "hmupd8";
    runtimeInputs = [hmswitch];
    text = ''
      pushd ~/projects/dotfiles
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
  home.packages =
    (lib.optionals isNixOS [
      nix-current-generation
      ndefault
      nbuild
      nswitch
      upd8
    ])
    ++ [
      hmbuild
      hmswitch
      hmupd8
      ngc
    ];
}
