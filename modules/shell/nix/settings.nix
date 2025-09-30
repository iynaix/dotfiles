{
  config,
  dots,
  inputs,
  lib,
  pkgs,
  self,
  user,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs
    mapAttrsToList
    mkOverride
    sort
    ;
in
{
  environment = {
    systemPackages = with pkgs; [
      comma
      nix-init
      nix-output-monitor
      nix-tree
      nix-update
      nixd
      nixfmt
      nixfmt
      nixpkgs-review
      nvfetcher
    ];

    shellAliases = {
      nfl = "nix flake lock";
      nfu = "nix flake update";
      nsh = "nix-shell --command fish -p";
      nshp = "nix-shell --pure --command fish -p";
    };
  };

  programs = {
    nh = {
      enable = true;
      flake = dots;
    };

    nix-index.enable = true;

    # run unpatched binaries on nixos
    nix-ld.enable = true;
  };

  # execute shebangs that assume hardcoded shell paths
  services.envfs.enable = true;
  system = {
    # envfs sets usrbinenv activation script to "" with mkForce
    activationScripts.usrbinenv = mkOverride (50 - 1) ''
      if [ ! -d "/usr/bin" ]; then
        mkdir -p /usr/bin
        chmod 0755 /usr/bin
      fi
    '';

    # make a symlink of flake within the generation (e.g. /run/current-system/src)
    extraSystemBuilderCmds = "ln -s ${self.sourceInfo.outPath} $out/src";
  };

  # i dgaf
  nixpkgs.config.allowUnfree = true;

  nix =
    let
      nixPath = mapAttrsToList (name: _: "${name}=flake:${name}") inputs;
      registry = mapAttrs (_: flake: { inherit flake; }) inputs;
    in
    {
      channel.enable = false;
      # required for nix-shell -p to work
      inherit nixPath;
      gc = {
        # Automatic garbage collection
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 7d";
      };
      # package = pkgs.lixPackageSets.latest.lix;
      package = pkgs.nixVersions.latest;
      registry = registry // {
        n = registry.nixpkgs;
        master = {
          from = {
            type = "indirect";
            id = "nixpkgs-master";
          };
          to = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
          };
        };
      };
      settings = {
        auto-optimise-store = true; # Optimise symlinks
        # re-evaluate on every rebuild instead of "cached failure of attribute" error
        # eval-cache = false;
        flake-registry = ""; # don't use the global flake registry, define everything explicitly
        # required to be set, for some reason nix.nixPath does not write to nix.conf
        nix-path = nixPath;
        warn-dirty = false;
        # removes ~/.nix-profile and ~/.nix-defexpr
        use-xdg-base-directories = true;

        # use flakes
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
        ];
        # allow building and pushing of laptop config from desktop
        trusted-users = [ user ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

  # never going to read html docs locally
  documentation = {
    enable = true;
    doc.enable = true;
    man.enable = true;
    dev.enable = false;
  };

  # enable man-db cache for fish to be able to find manpages
  # https://discourse.nixos.org/t/fish-shell-and-manual-page-completion-nixos-home-manager/15661
  documentation.man.generateCaches = true;

  system = {
    # use nixos-rebuild-ng to rebuild the system
    rebuild.enableNg = true;

    # better nixos generation label
    # https://reddit.com/r/NixOS/comments/16t2njf/small_trick_for_people_using_nixos_with_flakes/k2d0sxx/
    nixos.label = concatStringsSep "-" (
      (sort (x: y: x < y) config.system.nixos.tags)
      ++ [ "${config.system.nixos.version}.${self.sourceInfo.shortRev or "dirty"}" ]
    );
  };

  systemd.tmpfiles.rules = [
    # cleanup nixpkgs-review cache on boot
    "D! ${config.hj.xdg.cache.directory}/nixpkgs-review 1755 ${user} users 5d"
    # cleanup channels so nix stops complaining
    "D! /nix/var/nix/profiles/per-user/root 1755 root root 1d"
  ];

  custom.persist = {
    home = {
      cache.directories = [
        ".cache/nix"
        ".cache/nix-index"
      ];
    };
  };
}
