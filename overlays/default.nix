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
      # include custom packages
      custom =
        (prev.custom or { })
        // {
          lib = pkgs.callPackage ./lib.nix { };
        }
        // (import ../packages {
          inherit (prev) pkgs;
          inherit inputs;
        });

      # nixos-small logo looks like ass
      fastfetch = prev.fastfetch.overrideAttrs (
        o: { patches = (o.patches or [ ]) ++ [ ./fastfetch-nixos-old-small.patch ]; }
      );

      # easier access to ghostty
      ghostty = inputs.ghostty.packages.${pkgs.system}.default;

      # patch imv to not repeat keypresses causing waybar to launch infinitely
      # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
      imv =
        assert (lib.assertMsg (prev.imv.version == "4.5.0")
          "imv: is keypress patch still needed? is freeimage override still needed?"
        );
        prev.imv.overrideAttrs (
          o: {
            patches = (o.patches or [ ]) ++ [
              # https://lists.sr.ht/~exec64/imv-devel/patches/39476
              ./imv-fix-repeated-keypresses.patch
            ];
          }
        );

      # add default font to silence null font errors
      lsix = prev.lsix.overrideAttrs (
        o: {
          postFixup = ''
            substituteInPlace $out/bin/lsix \
              --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${o.postFixup}
          '';
        }
      );

      # nixos-small logo looks like ass
      neofetch = prev.neofetch.overrideAttrs (
        o: { patches = (o.patches or [ ]) ++ [ ./neofetch-nixos-small.patch ]; }
      );

      # fix nix package count for nitch
      nitch = prev.nitch.overrideAttrs (
        o: { patches = (o.patches or [ ]) ++ [ ./nitch-nix-pkgs-count.patch ]; }
      );

      path-of-building =
        let
          desktopItem = pkgs.makeDesktopItem {
            name = "Path of Building";
            desktopName = "Path of Building";
            comment = "Offline build planner for Path of Exile";
            exec = "pobfrontend %U";
            terminal = false;
            type = "Application";
            icon = ./PathOfBuilding-logo.png;
            categories = [ "Game" ];
            keywords = [
              "poe"
              "pob"
              "pobc"
              "path"
              "exile"
            ];
            mimeTypes = [ "x-scheme-handler/pob" ];
          };
          data = prev.path-of-building.passthru.data.overrideAttrs sources.path-of-building;
        in
        prev.path-of-building.overrideAttrs (
          _: {
            inherit (sources.path-of-building) version;

            postInstall = ''
              mkdir -p $out/share/applications
              cp ${desktopItem}/share/applications/* $out/share/applications
            '';

            preFixup = ''
              qtWrapperArgs+=(
                --set LUA_PATH "$LUA_PATH"
                --set LUA_CPATH "$LUA_CPATH"
                --chdir "${data}"
              )
            '';
          }
        );

      # use latest commmit from git
      # swww = prev.swww.overrideAttrs (
      #   _:
      #   sources.swww
      #   // {
      #     # creating an overlay for buildRustPackage overlay
      #     # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
      #     cargoDeps = prev.rustPlatform.importCargoLock {
      #       lockFile = sources.swww.src + "/Cargo.lock";
      #       allowBuiltinFetchGit = true;
      #     };
      #   }
      # );

      # use dev branch
      # wallust = prev.wallust.overrideAttrs (_:
      #   sources.wallust
      #   // {
      #     # creating an overlay for buildRustPackage overlay
      #     # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
      #     cargoDeps = prev.rustPlatform.importCargoLock {
      #       lockFile = sources.wallust.src + "/Cargo.lock";
      #       allowBuiltinFetchGit = true;
      #     };
      #   });

      # use latest commmit from git
      waybar =
        let
          # Derived from subprojects/cava.wrap
          libcava = rec {
            version = "0.10.1";
            src = pkgs.fetchFromGitHub {
              owner = "LukashonakV";
              repo = "cava";
              rev = version;
              hash = "sha256-iIYKvpOWafPJB5XhDOSIW9Mb4I3A4pcgIIPQdQYEqUw=";
            };
          };
        in
        assert (lib.assertMsg (prev.waybar.version == "0.9.24") "waybar: use waybar from nixpkgs?");
        prev.waybar.overrideAttrs (
          o:
          sources.waybar
          // {
            version = "${o.version}-${sources.waybar.version}";
            mesonFlags = lib.remove "-Dgtk-layer-shell=enabled" o.mesonFlags;
            postUnpack = ''
              pushd "$sourceRoot"
              cp -R --no-preserve=mode,ownership ${libcava.src} subprojects/cava-${libcava.version}
              patchShebangs .
              popd
            '';
          }
        );
    })
  ];
}
