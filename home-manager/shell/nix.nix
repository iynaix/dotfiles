{
  pkgs,
  host,
  ...
}: let
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
  home.packages = [
    hmbuild
    hmswitch
    hmupd8
    ngc
  ];
}
