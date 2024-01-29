{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # include generated sources from nvfetcher
  sources = import ./generated.nix {inherit (pkgs) fetchFromGitHub fetchurl fetchgit dockerTools;};
in {
  nixpkgs.overlays = [
    (
      _: prev: {
        # include custom packages
        custom =
          (prev.custom or {})
          // {lib = pkgs.callPackage ./lib.nix {};}
          // (import ../packages {
            inherit (prev) pkgs;
            inherit inputs;
          });

        # nixos-small logo looks like ass
        fastfetch = prev.fastfetch.overrideAttrs (o: {
          patches = (o.patches or []) ++ [./fastfetch-nixos-old-small.patch];
        });

        # easier access to ghostty
        ghostty = inputs.ghostty.packages.${pkgs.system}.default;

        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = assert (lib.assertMsg (prev.imv.version == "4.4.0") "imv: is keypress patch still needed?");
          prev.imv.overrideAttrs (o: {
            patches =
              (o.patches or [])
              ++ [
                # https://lists.sr.ht/~exec64/imv-devel/patches/39476
                ./imv-fix-repeated-keypresses.patch
              ];
          });

        # add default font to silence null font errors
        lsix = prev.lsix.overrideAttrs (o: {
          postFixup = ''
            substituteInPlace $out/bin/lsix \
              --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${o.postFixup}
          '';
        });

        # nixos-small logo looks like ass
        neofetch = prev.neofetch.overrideAttrs (o: {
          patches = (o.patches or []) ++ [./neofetch-nixos-small.patch];
        });

        # fix nix package count for nitch
        nitch = prev.nitch.overrideAttrs (o: {
          patches = (o.patches or []) ++ [./nitch-nix-pkgs-count.patch];
        });

        rclip = prev.rclip.overridePythonAttrs (o: {
          version = "1.7.24";

          src = prev.fetchFromGitHub {
            owner = "yurijmikhalevich";
            repo = "rclip";
            rev = "v1.7.24";
            hash = "sha256-JWtKgvSP7oaPg19vWnnCDfm7P5Uew+v9yuvH7y2eHHM=";
          };

          nativeBuildInputs = o.nativeBuildInputs ++ [pkgs.python3Packages.pythonRelaxDepsHook];

          pythonRelaxDeps = ["torch" "torchvision"];
        });

        # use latest commmit from git
        swww = prev.swww.overrideAttrs (_:
          sources.swww
          // {
            # creating an overlay for buildRustPackage overlay
            # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
            cargoDeps = prev.rustPlatform.importCargoLock {
              lockFile = sources.swww.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          });

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

        # lock vscode to 1.81.1 because native titlebar causes vscode to crash
        # https://github.com/microsoft/vscode/issues/184124#issuecomment-1717959995
        vscode = assert (lib.assertMsg (lib.hasPrefix "1.85" prev.vscode.version) "vscode: has wayland crash been fixed?");
          prev.vscode.overrideAttrs (_: let
            version = "1.81.1";
            plat = "linux-x64";
          in {
            src = prev.fetchurl {
              name = "VSCode_${version}_${plat}.tar.gz";
              url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
              sha256 = "sha256-Tqawqu0iR0An3CZ4x3RGG0vD3x/PvQyRhVThc6SvdEg=";
            };
            # preFixup = ''
            #   gappsWrapperArgs+=(
            #     # Add gio to PATH so that moving files to the trash works when not using a desktop environment
            #     --prefix PATH : ${prev.glib.bin}/bin
            #     --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
            #     --add-flags ${lib.escapeShellArg commandLineArgs}
            #   )
            # '';
          });

        # use latest commmit from git
        waybar = assert (lib.assertMsg (prev.waybar.version == "0.9.24") "waybar: use waybar from nixpkgs?");
          prev.waybar.overrideAttrs (o:
            sources.waybar // {version = "${o.version}-${sources.waybar.version}";});
      }
    )
  ];
}
