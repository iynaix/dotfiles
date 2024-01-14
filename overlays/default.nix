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
      _: prev: let
        overrideRustPackage = pkgname:
          prev.${pkgname}.overrideAttrs (_:
            sources.${pkgname}
            // {
              # creating an overlay for buildRustPackage overlay
              # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
              cargoDeps = prev.rustPlatform.importCargoLock {
                lockFile = sources.${pkgname}.src + "/Cargo.lock";
                allowBuiltinFetchGit = true;
              };
            });
      in {
        # include custom packages
        iynaix =
          (prev.iynaix or {})
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
          nativeBuildInputs = o.nativeBuildInputs ++ [pkgs.python3Packages.pythonRelaxDepsHook];

          pythonRelaxDeps = ["torch" "torchvision"];
        });

        # use latest commmit from git
        swww = overrideRustPackage "swww";

        # use dev branch
        # wallust = overrideRustPackage "wallust";

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
      }
    )
  ];
}
