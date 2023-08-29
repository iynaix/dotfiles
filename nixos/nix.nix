{
  pkgs,
  host,
  lib,
  user,
  ...
}: let
  dots = "/persist/home/${user}/projects/dotfiles";
  # outputs the current nixos generation
  nix-current-generation = pkgs.writeShellScriptBin "nix-current-generation" ''
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'
  '';
  # set the current configuration as default to boot
  ndefault = pkgs.writeShellScriptBin "ndefault" ''
    sudo /run/current-system/bin/switch-to-configuration boot
  '';
  # build flake but don't switch
  nbuild = pkgs.writeShellApplication {
    name = "nbuild";
    runtimeInputs = with pkgs; [git nix-output-monitor];
    text = ''
      pushd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      sudo nixos-rebuild build --flake ".#''${1:-${host}} |& nom"
      popd
    '';
  };
  # switch via nix flake
  nswitch = pkgs.writeShellApplication {
    name = "nswitch";
    runtimeInputs = with pkgs; [nix-current-generation git nvd nix-output-monitor];
    text = ''
      pushd ${dots}

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      prev=$(readlink /run/current-system)
      sudo nixos-rebuild switch --flake ".#''${1:-${host}}" |& nom && {
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
      pushd ${dots}
      nix flake update
      nswitch
      popd
    '';
  };
  # build and push config for laptop
  nswitch-remote = pkgs.writeShellApplication {
    name = "nswitch-remote";
    text = ''
      pushd ${dots}
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
  # create an fhs environment to run downloaded binaries
  # https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos
  fhs = let
    base = pkgs.appimageTools.defaultFhsEnvArgs;
  in
    pkgs.buildFHSUserEnv (base
      // {
        name = "fhs";
        targetPkgs = pkgs: (
          # pkgs.buildFHSUserEnv provides only a minimal FHS environment,
          # lacking many basic packages needed by most software.
          # Therefore, we need to add them manually.
          #
          # pkgs.appimageTools provides basic packages required by most software.
          (base.targetPkgs pkgs)
          ++ [
            pkgs.pkg-config
            pkgs.ncurses
            # Feel free to add more packages here if needed.
          ]
        );
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = ["dev"];
      });
in {
  environment.systemPackages =
    [
      pkgs.nix-output-monitor
      nix-current-generation
      ndefault
      nbuild
      nswitch
      upd8
      fhs
    ]
    ++ lib.optionals (host == "desktop") [
      nswitch-remote
      sync-wallpapers
    ];

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
