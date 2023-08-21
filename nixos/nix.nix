{
  pkgs,
  host,
  lib,
  user,
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
    git add .
    sudo nixos-rebuild build --flake ".#''${1:-${host}}"
    popd
  '';
  # switch via nix flake
  nswitch = pkgs.writeShellApplication {
    name = "nswitch";
    runtimeInputs = [nix-current-generation pkgs.nvd];
    text = ''
      pushd ~/projects/dotfiles
      git add .
      prev=$(readlink /run/current-system)

      sudo nixos-rebuild switch --flake ".#''${1:-${host}}" && {
        nvd diff "$prev" "$(readlink /run/current-system)"
        echo -e "Switched to Generation \033[1m$(nix-current-generation)\033[0m"
      }
      popd
    '';
  };
  # update via nix flake
  upd8 = pkgs.writeShellApplication {
    name = "upd8";
    runtimeInputs = [nswitch];
    # command ls -d /nix/var/nix/profiles/* | rg link | sort | tail -n2 | xargs -d '\n' nvd diff
    text = ''
      pushd ~/projects/dotfiles
      nix flake update
      nswitch
      popd
    '';
  };
  # build and push config for laptop
  nswitch-remote = pkgs.writeShellApplication {
    name = "nswitch-remote";
    text = ''
      pushd ~/projects/dotfiles
      sudo nixos-rebuild --target-host "root@''${1:-iynaix-laptop}" --flake ".#''${2:-laptop}" switch
      popd
    '';
  };
  # sync wallpapers with laptop
  sync-wallpapers = pkgs.writeShellApplication {
    name = "sync-wallpapers";
    text = ''
      rsync -aP --delete --no-links -e "ssh" "$HOME/Pictures/Wallpapers" "${user}@''${1:-iynaix-laptop}:$HOME/Pictures"
    '';
  };
in {
  environment.systemPackages =
    [
      nix-current-generation
      ndefault
      nbuild
      nswitch
      upd8
    ]
    ++ lib.optionals (host == "desktop") [
      nswitch-remote
      sync-wallpapers
    ];

  programs.zsh.shellAliases = {
    nsw = "nswitch";
  };

  # enable flakes
  nix = {
    settings = {
      auto-optimise-store = true; # Optimise syslinks
      substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    gc = {
      # Automatic garbage collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
    package = pkgs.nixVersions.unstable;
    # use flakes
    extraOptions = "experimental-features = nix-command flakes";
  };
}
