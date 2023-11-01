{
  host,
  inputs,
  lib,
  pkgs,
  user,
  ...
}: let
  dots = "/persist/home/${user}/projects/dotfiles";
  # outputs the current nixos generation
  nix-current-generation = pkgs.writeShellScriptBin "nix-current-generation" ''
    generations=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
    # add generation number from before desktop format
    echo $(expr $generations + ${
      if host == "desktop"
      then "1196"
      else "0"
    })
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
      # build for current flake if a flake.nix exists
      if [ ! -f flake.nix ]; then
        pushd ${dots}
      fi

      # stop bothering me about untracked files
      untracked_files=$(git ls-files --exclude-standard --others .)
      if [ -n "$untracked_files" ]; then
          git add "$untracked_files"
      fi

      nixos-rebuild build --flake ".#''${1:-${host}}" |& nom
      if [ ! -f flake.nix ]; then
        popd
      fi
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
      nvfetcher
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
    runtimeInputs = with pkgs; [rsync];
    text = ''
      rsync -aP --delete --no-links -e "ssh -o StrictHostKeyChecking=no" "$HOME/Pictures/Wallpapers" "${user}@''${1:-iynaix-laptop}:$HOME/Pictures"
    '';
  };
  json2nix = pkgs.writeShellApplication {
    name = "json2nix";
    runtimeInputs = with pkgs; [hjson alejandra];
    text = ''
      json=$(echo "$1" | hjson -j 2> /dev/null)
      nix eval --expr "builtins.fromJSON '''$json'''" | alejandra
    '';
  };
  yaml2nix = pkgs.writeShellApplication {
    name = "yaml2nix";
    runtimeInputs = with pkgs; [yq alejandra];
    text = ''
      yaml=$(echo "$1" | yq)
      nix eval --expr "builtins.fromJSON '''$yaml'''" | alejandra
    '';
  };
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
in {
  environment.systemPackages =
    [
      pkgs.nix-output-monitor
      nix-current-generation
      ndefault
      nbuild
      nswitch
      upd8
      json2nix
      yaml2nix
      # fhs
      inputs.nvfetcher.packages.${pkgs.system}.default # nvfetcher
    ]
    ++ lib.optionals (host == "desktop") [
      nswitch-remote
      sync-wallpapers
    ];

  # enable flakes
  nix = {
    settings = {
      auto-optimise-store = true; # Optimise symlinks
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
