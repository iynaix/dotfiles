{
  config,
  dots,
  host,
  inputs,
  lib,
  pkgs,
  self,
  user,
  ...
}:
let
  inherit (lib)
    concatLines
    concatStringsSep
    getExe
    mkOverride
    optionalAttrs
    sort
    ;
in
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
{
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

  # run unpatched binaries on nixos
  programs.nix-ld.enable = true;

  environment = {
    # for nixlang / nixpkgs
    systemPackages = with pkgs; [
      nix-init
      nix-update
      nixfmt-rfc-style
    ];
  };

  systemd.tmpfiles.rules = [
    # cleanup nixpkgs-review cache on boot
    "D! ${config.hm.xdg.cacheHome}/nixpkgs-review 1755 ${user} users 5d"
    # cleanup channels so nix stops complaining
    "D! /nix/var/nix/profiles/per-user/root 1755 root root 1d"
  ];

  custom.shell.packages =
    {
      # build iso images
      nbuild-iso = {
        runtimeInputs = [ pkgs.nixos-generators ];
        text = # sh
          ''
            pushd ${dots} > /dev/null
            nix build ".#nixosConfigurations.$1.config.system.build.isoImage"
            popd > /dev/null
          '';
        fishCompletion = # fish
          ''
            function _nbuild_iso
              nix eval --impure --json --expr \
                'with builtins.getFlake (toString ./.); builtins.attrNames nixosConfigurations' | \
                ${getExe pkgs.jq} -r '.[]' | grep iso
              end
              complete -c nbuild-iso -f -a '(_nbuild_iso)'
          '';
      };
      # list all installed packages
      nix-list-packages = {
        text =
          let
            allPkgs = map (p: p.name) (
              config.environment.systemPackages ++ config.users.users.${user}.packages ++ config.hm.home.packages
            );
          in
          ''sort -ui <<< "${concatLines allPkgs}"'';
      };
    }
    // optionalAttrs (host == "desktop") {
      # build and push config for laptop
      nsw-remote = # sh
        ''
          pushd ${dots} > /dev/null
          nixos-rebuild switch --target-host "root@''${1:-framework}" --flake ".#''${2:-framework}"
          popd > /dev/null
        '';
    };

  # never going to read html docs locally
  documentation = {
    enable = true;
    doc.enable = true;
    man.enable = true;
    dev.enable = false;
  };

  nix =
    let
      nixPath = [
        "nixpkgs=flake:nixpkgs"
        # "/nix/var/nix/profiles/per-user/root/channels"
      ];
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
      package = pkgs.nixVersions.latest;
      registry = {
        n.flake = inputs.nixpkgs-stable;
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
        stable.flake = inputs.nixpkgs-stable;
      };
      settings = {
        auto-optimise-store = true; # Optimise symlinks
        # re-evaluate on every rebuild instead of "cached failure of attribute" error
        # eval-cache = false;
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
          # "repl-flake"
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
      # // optionalAttrs (config.nix.package.pname == "lix") {
      #   repl-overlays = [ ./repl-overlays.nix ];
      # };
    };

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

  # enable man-db cache for fish to be able to find manpages
  # https://discourse.nixos.org/t/fish-shell-and-manual-page-completion-nixos-home-manager/15661
  documentation.man.generateCaches = true;

  hm.custom.persist = {
    home = {
      cache.directories = [
        ".cache/nix"
        ".cache/nixpkgs-review"
      ];
    };
  };
}
