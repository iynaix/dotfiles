{
  config,
  inputs,
  lib,
  pkgs,
  self,
  user,
  ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  config = {
    environment = {
      systemPackages = with pkgs; [
        nil
        nix-init
        nix-output-monitor
        nix-graph
        nix-update
        nixd
        nixfmt-rs
        nixpkgs-review
      ];

      shellAliases = {
        nfl = "nix flake lock";
        nsh = "nix-shell --command fish -p";
        nshp = "nix-shell --pure --command fish -p";
      };
    };

    programs = {
      nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 5d --keep 5";
        };
        flake = "/persist/home/${user}/projects/dotfiles";
      };

      nix-index.enable = true;
      command-not-found.enable = false;

      # run unpatched binaries on nixos
      nix-ld.enable = true;
    };

    # i dgaf
    nixpkgs.config.allowUnfree = true;

    nix =
      let
        flake-inputs = lib.filterAttrs (
          name: input: !(lib.hasPrefix "_" name) && !(lib.isString input) && (lib.isType "flake" input)
        ) inputs;
        registry = lib.mapAttrs (_: flake: { inherit flake; }) flake-inputs;
      in
      {
        channel.enable = false;
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
          # for nix flake init
          templates = {
            from = {
              id = "templates";
              type = "indirect";
            };
            to = {
              type = "github";
              owner = "NixOS";
              repo = "templates";
            };
          };
        };
        optimise.automatic = true;
        settings = {
          flake-registry = ""; # don't use the global flake registry, define everything explicitly
          nix-path = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flake-inputs;
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
            "https://nix-community.cachix.org"
          ];

          # allow building and pushing of laptop config from desktop
          trusted-users = [ user ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };
        extraOptions = ''
          !include ${config.sops.secrets.nix_extra_config.path}
        '';
      };

    # setup github auth token for nix to use
    sops.secrets.nix_extra_config.owner = user;

    # never going to read html docs locally
    documentation = {
      enable = false;
      doc.enable = false;
      man = {
        enable = true;
        # enable man-db cache for fish to be able to find manpages
        # https://discourse.nixos.org/t/fish-shell-and-manual-page-completion-nixos-home-manager/15661
        cache.enable = true;
      };
      nixos.enable = false;
      dev.enable = false;
    };

    # execute shebangs that assume hardcoded shell paths
    services.envfs.enable = true;

    system = {
      # make a symlink of flake within the generation (e.g. /run/current-system/src)
      systemBuilderCommands = "ln -s ${self.sourceInfo.outPath} $out/src";
    };

    systemd.tmpfiles.rules = [
      # cleanup nixpkgs-review cache on boot
      "D! /home/${user}/.cache/nixpkgs-review 1755 ${user} users 5d"
      # cleanup channels so nix stops complaining
      "D! /nix/var/nix/profiles/per-user/root 1755 root root 1d"
    ];

    custom.persist = {
      root = {
        cache.directories = [
          "/var/cache/man/nixos-mandb"
          "/var/cache/man/nixos-manpages"
        ];
      };
      home = {
        cache.directories = [
          ".cache/nix"
          ".cache/nix-index"
        ];
      };
    };
  };
}
