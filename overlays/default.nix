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
        // {
          lib = pkgs.callPackage ./lib.nix { inherit (prev) pkgs; };
        }
        // (import ../packages {
          inherit (prev) pkgs;
          inherit inputs;
        });

      # TODO: remove when xlib is updated upstream
      python312 = prev.python312.override {
        packageOverrides = _: pysuper: { xlib = pysuper.xlib.overridePythonAttrs { doCheck = false; }; };
      };

      # nixos-small logo looks like ass
      fastfetch = prev.fastfetch.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./fastfetch-nixos-old-small.patch ];
      });

      # add default font to silence null font errors
      lsix = prev.lsix.overrideAttrs (o: {
        postFixup = ''
          substituteInPlace $out/bin/lsix \
            --replace-fail '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
          ${o.postFixup}
        '';
      });

      # fix nix package count for nitch
      nitch = prev.nitch.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./nitch-nix-pkgs-count.patch ];
      });

      # use nixfmt-rfc-style as the default
      nixfmt = prev.nixfmt-rfc-style;

      /*
        path-of-building = prev.path-of-building.overrideAttrs (o: {
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
        });
      */

      scope-tui = prev.scope-tui.overrideAttrs (
        o:
        sources.scope-tui
        // {
          # do not copy custom cargo.lock
          postPatch = "";

          buildInputs = (o.buildInputs or [ ]) ++ [ prev.alsa-lib ];

          # creating an overlay for buildRustPackage overlay
          # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
          cargoDeps = prev.rustPlatform.importCargoLock {
            lockFile = sources.scope-tui.src + "/Cargo.lock";
            allowBuiltinFetchGit = true;
          };
        }
      );

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

      wallust =
        assert (lib.assertMsg (prev.wallust.version == "3.0.0-beta") "wallust: use wallust 3.0?");
        prev.wallust.overrideAttrs (
          _:
          sources.wallust
          // {
            # creating an overlay for buildRustPackage overlay
            # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
            cargoDeps = prev.rustPlatform.importCargoLock {
              lockFile = sources.wallust.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          }
        );
    })
  ];
}
