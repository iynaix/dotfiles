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
          // (import ../packages {
            inherit (prev) pkgs;
            inherit inputs;
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
        waybar = let
          version = "3.5.1";
          catch2_3 = assert (lib.assertMsg (prev.catch2_3.version != version) "catch2: override is no longer needed");
            prev.catch2_3.overrideAttrs (_: {
              inherit version;
              src = prev.fetchFromGitHub {
                owner = "catchorg";
                repo = "Catch2";
                rev = "v${version}";
                hash = "sha256-OyYNUfnu6h1+MfCF8O+awQ4Usad0qrdCtdZhYgOY+Vw=";
              };
            });
        in
          (prev.waybar.override {inherit catch2_3;}).overrideAttrs (o:
            sources.waybar
            // {
              version = "${o.version}-${sources.waybar.version}";
            });

        # fix yazi not supporting image previews in ghostty yet
        yazi = assert (lib.assertMsg (prev.yazi.version == "0.1.5") "yazi: overlay is no longer needed");
          prev.yazi.overrideAttrs (
            o: rec {
              version = "0.2.1";

              src = prev.fetchFromGitHub {
                owner = "sxyazi";
                repo = "yazi";
                rev = "v${version}";
                hash = "sha256-XdN2oP5c2lK+bR3i+Hwd4oOlccMQisbzgevHsZ8YbSQ=";
              };

              env.YAZI_GEN_COMPLETIONS = true;

              # creating an overlay for buildRustPackage overlay
              # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
              cargoDeps = prev.rustPlatform.importCargoLock {
                lockFile = src + "/Cargo.lock";
                allowBuiltinFetchGit = true;
              };

              postInstall = lib.replaceStrings ["./config"] ["./yazi-config"] o.postInstall;
            }
          );
      }
    )
  ];
}
