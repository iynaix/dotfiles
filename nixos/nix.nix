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
    activationScripts.usrbinenv = lib.mkOverride (50 - 1) ''
      mkdir -p /usr/bin
      chmod 0755 /usr/bin || true
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
      # set the current generation or given generation number as default to boot
      ndefault = {
        text = ''
          if [ "$#" -eq 0 ]; then
            sudo /run/current-system/bin/switch-to-configuration boot
          else
            sudo "/nix/var/nix/profiles/system-$1-link/bin/switch-to-configuration" boot
          fi
        '';
        bashCompletion = ''
          _ndefault() {
              local profile_dir="/nix/var/nix/profiles"
              local profiles=$(command ls -1 "$profile_dir" | \
                  grep -E '^system-[0-9]+-link$' | \
                  sed -E 's/^system-([0-9]+)-link$/\1/' | \
                  sort -rnu)
              COMPREPLY=($(compgen -W "$profiles" -- "''${COMP_WORDS[COMP_CWORD]}"))
          }

          complete -F _ndefault ndefault
        '';
        fishCompletion = ''
          function _ndefault
              set -l profile_dir "/nix/var/nix/profiles"
              command ls -1 "$profile_dir" | \
                string match -r '^system-([0-9]+)-link$' | \
                string replace -r '^system-([0-9]+)-link$' '$1' | \
                sort -ru
          end

          complete --keep-order -c ndefault -f -a "(_ndefault)"
        '';
      };
      # build iso images
      nbuild-iso = {
        runtimeInputs = [ pkgs.nixos-generators ];
        text = ''
          pushd ${dots} > /dev/null
          nix build ".#nixosConfigurations.$1.config.system.build.isoImage"
          popd > /dev/null
        '';
        fishCompletion = ''
          function _nbuild_iso
            nix eval --impure --json --expr \
              'with builtins.getFlake (toString ./.); builtins.attrNames nixosConfigurations' | \
              ${lib.getExe pkgs.jq} -r '.[]' | grep iso
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
          ''sort -ui <<< "${lib.concatLines allPkgs}"'';
      };
    }
    // lib.optionalAttrs (host == "desktop") {
      # build and push config for laptop
      nsw-remote = ''
        pushd ${dots} > /dev/null
        nixos-rebuild switch --target-host "root@''${1:-${user}-framework}" --flake ".#''${2:-framework}"
        popd > /dev/null
      '';
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
      # // lib.optionalAttrs (config.nix.package.pname == "lix") {
      #   repl-overlays = [ ./repl-overlays.nix ];
      # };
    };

  # better nixos generation label
  # https://reddit.com/r/NixOS/comments/16t2njf/small_trick_for_people_using_nixos_with_flakes/k2d0sxx/
  system.nixos.label = lib.concatStringsSep "-" (
    (lib.sort (x: y: x < y) config.system.nixos.tags)
    ++ [ "${config.system.nixos.version}.${self.sourceInfo.shortRev or "dirty"}" ]
  );

  # add nixos-option workaround for flakes
  # https://github.com/NixOS/nixpkgs/issues/97855#issuecomment-1075818028
  nixpkgs.overlays = [
    (_: prev: {
      nixos-option =
        let
          flake-compat = prev.fetchFromGitHub {
            owner = "edolstra";
            repo = "flake-compat";
            rev = "12c64ca55c1014cdc1b16ed5a804aa8576601ff2";
            hash = "sha256-hY8g6H2KFL8ownSiFeMOjwPC8P0ueXpCVEbxgda3pko=";
          };
          prefix = ''(import ${flake-compat} { src = ${dots}; }).defaultNix.nixosConfigurations.${host}'';
        in
        prev.runCommandNoCC "nixos-option" { buildInputs = [ prev.makeWrapper ]; } ''
          makeWrapper ${lib.getExe prev.nixos-option} $out/bin/nixos-option \
            --add-flags --config_expr \
            --add-flags "\"${prefix}.config\"" \
            --add-flags --options_expr \
            --add-flags "\"${prefix}.options\""
        '';
    })
  ];

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
