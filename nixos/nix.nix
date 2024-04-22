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

  custom-nixos.shell.packages =
    {
      # set the current configuration as default to boot
      ndefault = ''
        sudo /run/current-system/bin/switch-to-configuration boot
      '';
      # build iso images
      nbuild-iso = pkgs.writeShellApplication {
        name = "nbuild-iso";
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
      nsw-remote = pkgs.writeShellApplication {
        name = "nsw-remote";
        text = ''
          cd ${dots}
          sudo nixos-rebuild --target-host "root@''${1:-${user}-laptop}" --flake ".#''${2:-framework}" switch
          cd - > /dev/null
        '';
      };
    };

  nix = {
    # channel.enable = false;
    gc = {
      # Automatic garbage collection
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixUnstable;
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
      eval-cache = false;
      warn-dirty = false;
      # removes ~/.nix-profile and ~/.nix-defexpr
      use-xdg-base-directories = true;

      # use flakes
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake" # allows use of a flake via nix repl ".#desktop"
      ];
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://ghostty.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      # allow building and pushing of laptop config from desktop
      trusted-users = [ user ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };

  # better nixos generation label
  # https://reddit.com/r/NixOS/comments/16t2njf/small_trick_for_people_using_nixos_with_flakes/k2d0sxx/
  system.nixos.label = lib.concatStringsSep "-" (
    (lib.sort (x: y: x < y) config.system.nixos.tags)
    ++ [ "${config.system.nixos.version}.${self.sourceInfo.shortRev or "dirty"}" ]
  );

  hm.custom.persist = {
    home = {
      cache = [
        ".cache/nix"
        ".cache/nixpkgs-review"
      ];
    };
  };
}
