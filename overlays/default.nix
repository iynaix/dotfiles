{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # include generated sources from nvfetcher
  sources = import ./generated.nix {
    inherit (pkgs)
      fetchFromGitHub
      fetchurl
      fetchgit
      dockerTools
      ;
  };
in
{
  nixpkgs.overlays = [
    (_: prev: {
      # include nixpkgs stable
      stable = import inputs.nixpkgs-stable {
        inherit (prev.pkgs) system;
        config.allowUnfree = true;
      };

      # include custom packages
      custom =
        (prev.custom or { })
        // (import ../packages {
          inherit (prev) pkgs;
          inherit inputs;
        });

      # nixos-small logo looks like ass
      fastfetch = prev.fastfetch.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./fastfetch-nixos-old-small.patch ];
      });

      # add default font to silence null font errors
      lsix = prev.lsix.overrideAttrs (o: {
        postFixup = ''
          substituteInPlace $out/bin/lsix \
            --replace-fail '#fontfamily=Mincho' 'fontfamily="MapleMono-NF-Regular"'
          ${o.postFixup}
        '';
      });

      # fix nix package count for nitch
      nitch = prev.nitch.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./nitch-nix-pkgs-count.patch ];
      });

      # use nixfmt-rfc-style as the default
      nixfmt = prev.nixfmt-rfc-style;

      path-of-building = prev.path-of-building.overrideAttrs {
        inherit (sources.path-of-building) version;

        preFixup =
          let
            data = prev.path-of-building.passthru.data.overrideAttrs sources.path-of-building;
          in
          ''
            qtWrapperArgs+=(
              --set LUA_PATH "$LUA_PATH"
              --set LUA_CPATH "$LUA_CPATH"
              --chdir "${data}"
            )
          '';
      };

      swww = prev.swww.overrideAttrs (
        sources.swww
        // {
          # creating an overlay for buildRustPackage overlay
          # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
          cargoDeps = prev.rustPlatform.importCargoLock {
            lockFile = sources.swww.src + "/Cargo.lock";
            allowBuiltinFetchGit = true;
          };
        }
      );

      # wallust = prev.wallust.overrideAttrs (
      #   sources.wallust
      #   // {
      #     # creating an overlay for buildRustPackage overlay
      #     # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
      #     cargoDeps = prev.rustPlatform.importCargoLock {
      #       lockFile = sources.wallust.src + "/Cargo.lock";
      #       allowBuiltinFetchGit = true;
      #     };
      #   }
      # );

      # hiding waybar is currently broken
      # https://github.com/Alexays/Waybar/issues/3477
      waybar =
        assert (lib.assertMsg (prev.waybar.version == "0.10.4") "waybar: use version from nixpkgs?");
        prev.waybar.overrideAttrs {
          src = prev.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "d56dd6ee7fdf8c5ba4e90790af62b7f7829d3a47";
            hash = "sha256-3lc0voMU5RS+mEtxKuRayq/uJO09X7byq6Rm5NZohq8=";
          };
        };

      # nsig keeps breaking, so use updated version from github
      yt-dlp = prev.yt-dlp.overrideAttrs sources.yt-dlp;
    })
  ];
}
