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

        # native titlebar causes vscode to crash, remove for vscode 1.86
        # https://github.com/microsoft/vscode/issues/184124#issuecomment-1717959995
        vscode = assert (lib.assertMsg (lib.hasPrefix "1.85" prev.vscode.version) "vscode: remove overlay");
          prev.vscode.overrideAttrs (_: rec {
            version = "1.86.0";
            plat = "linux-x64";

            src = prev.fetchurl {
              name = "VSCode_${version}_${plat}.tar.gz";
              url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
              sha256 = "0qykchhd6cplyip4gp5s1fpv664xw2y5z0z7n6zwhwpfrld8piwb";
            };

            rev = "05047486b6df5eb8d44b2ecd70ea3bdf775fd937";

            vscodeServer = prev.srcOnly {
              name = "vscode-server-${rev}.tar.gz";
              src = prev.fetchurl {
                name = "vscode-server-${rev}.tar.gz";
                url = "https://update.code.visualstudio.com/commit:${rev}/server-linux-x64/stable";
                sha256 = "0d3g6csi2aplsy5j3v84m65mhlg0krpb2sndk0nh7gafyc5gnn28";
              };
            };
          });

        # use latest commmit from git
        waybar = assert (lib.assertMsg (prev.waybar.version == "0.9.24") "waybar: use waybar from nixpkgs?");
          prev.waybar.overrideAttrs (o:
            sources.waybar // {version = "${o.version}-${sources.waybar.version}";});
      }
    )
  ];
}
