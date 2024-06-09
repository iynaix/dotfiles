{
  config,
  host,
  lib,
  pkgs,
  self,
  user,
  ...
}:
let
  dots = "/persist${config.hm.home.homeDirectory}/projects/dotfiles";
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

  # run unpatched binaries on nixos
  programs.nix-ld.enable = true;

  environment = {
    systemPackages =
      # for nixlang / nixpkgs
      with pkgs; [
        nil
        nix-init
        nix-update
        nixfmt-rfc-style
        nixpkgs-fmt
        nixpkgs-review
      ];
  };

  custom.shell.packages =
    {
      # set the current generation or given generation number as default to boot
      ndefault = ''
        if [ "$#" -eq 0 ]; then
          sudo /run/current-system/bin/switch-to-configuration boot
        else
          sudo "/nix/var/nix/profiles/system-$1-link/bin/switch-to-configuration" boot
        fi
      '';
      # build iso images
      nix-build-iso = {
        runtimeInputs = [ pkgs.nixos-generators ];
        text = ''
          cd ${dots}
          nix build ".#nixosConfigurations.$1.config.system.build.isoImage"
          cd - > /dev/null
        '';
      };
    }
    // lib.optionalAttrs (host == "desktop") {
      # build and push config for laptop
      nsw-remote = ''
        cd ${dots}
        sudo nixos-rebuild --target-host "root@''${1:-${user}-laptop}" --flake ".#''${2:-framework}" switch
        cd - > /dev/null
      '';
    };

  nix =
    let
      nixPath = [
        "nixpkgs=flake:nixpkgs"
        "/nix/var/nix/profiles/per-user/root/channels"
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
        nixpkgs-master = {
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
        nix-path = nixPath;
        warn-dirty = false;
        # removes ~/.nix-profile and ~/.nix-defexpr
        use-xdg-base-directories = true;

        # use flakes
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
          "https://ghostty.cachix.org"
        ];
        # allow building and pushing of laptop config from desktop
        trusted-users = [ user ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        ];
      };
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
          flake-compact = prev.fetchFromGitHub {
            owner = "edolstra";
            repo = "flake-compat";
            rev = "12c64ca55c1014cdc1b16ed5a804aa8576601ff2";
            sha256 = "sha256-hY8g6H2KFL8ownSiFeMOjwPC8P0ueXpCVEbxgda3pko=";
          };
          prefix = ''(import ${flake-compact} { src = ${dots}; }).defaultNix.nixosConfigurations.${host}'';
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

  hm.custom.persist = {
    home = {
      cache = [
        ".cache/nix"
        ".cache/nixpkgs-review"
      ];
    };
  };
}
