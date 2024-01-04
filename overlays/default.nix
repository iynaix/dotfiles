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

        # fix fish shell autocomplete error for zfs
        # https://github.com/NixOS/nixpkgs/issues/247290
        fish = assert (lib.assertMsg (lib.hasPrefix "3.6" prev.fish.version) "fish: overlay is no longer needed");
          prev.fish.overrideAttrs (o: {
            patches =
              (o.patches or [])
              ++ [
                (pkgs.fetchpatch {
                  name = "fix-zfs-completion.path";
                  url = "https://github.com/fish-shell/fish-shell/commit/85504ca694ae099f023ae0febb363238d9c64e8d.patch";
                  sha256 = "sha256-lA0M7E/Z0NjuvppC7GZA5rWdL7c+5l+3SF5yUe7nEz8=";
                })
              ];

            checkPhase = "";
          });

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

        # use latest commmit from git
        swww = overrideRustPackage "swww";

        # use dev branch
        # wallust = overrideRustPackage "wallust";

        # use latest commmit from git
        waybar = prev.waybar.overrideAttrs (o:
          sources.waybar
          // {
            version = "${o.version}-${sources.waybar.version}";
          });

        # fix wezterm crashing instantly on hyprland
        # https://github.com/wez/wezterm/issues/4483
        wezterm = assert (lib.assertMsg (prev.wezterm.version == "20230712-072601-f4abf8fd") "wezterm: overlay is no longer needed");
          overrideRustPackage "wezterm";
      }
    )
  ];
}
