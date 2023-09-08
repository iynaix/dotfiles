{
  inputs,
  pkgs,
  ...
}: let
  # include generated sources from nvfetcher
  sources = import ../_sources/generated.nix {inherit (pkgs) fetchFromGitHub fetchurl fetchgit dockerTools;};
in {
  nixpkgs.overlays = [
    (
      final: prev: {
        # include custom packages
        iynaix =
          (prev.iynaix or {})
          // (import ../packages {inherit (prev) pkgs;})
          // {
            hyprNStack = inputs.hyprNStack.packages.${pkgs.system}.hyprNStack;
          };

        # fix fish shell autocomplete error for zfs
        # https://github.com/NixOS/nixpkgs/issues/247290
        fish = prev.fish.overrideAttrs (o: {
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
        imv = prev.imv.overrideAttrs (o: {
          patches = (o.patches or []) ++ [./imv-disable-key-repeat-timer.patch];
        });

        # add default font to silence null font errors
        lsix = prev.lsix.overrideAttrs (o: {
          postFixup = ''
            substituteInPlace $out/bin/lsix \
              --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${o.postFixup}
          '';
        });

        # see below url for the latest specified version
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/path-of-building/default.nix
        path-of-building = prev.path-of-building.overrideAttrs (o: {
          passthru = o.passthru // o.passthru.data.overrideAttrs (_: {src = sources.path-of-building.src;});

          # add .desktop file with icon
          desktopItem = prev.makeDesktopItem {
            name = "Path of Building";
            desktopName = "Path of Building";
            comment = "Offline build planner for Path of Exile";
            exec = "pobfrontend %U";
            terminal = false;
            type = "Application";
            icon = ./PathOfBuilding-logo.png;
            categories = ["Game"];
            keywords = ["poe" "pob" "pobc" "path" "exile"];
            mimeTypes = ["x-scheme-handler/pob"];
          };
        });

        # use latest commmit from git
        swww = prev.swww.overrideAttrs (o:
          sources.swww
          // {
            version = "${o.version}-${sources.swww.version}";

            # creating an overlay for buildRustPackage overlay
            # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
            cargoDeps = prev.rustPlatform.importCargoLock {
              lockFile = sources.swww.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          });

        # transmission dark mode, the default theme is hideous
        transmission = let
          themeSrc = sources.transmission-web-soft-theme.src;
        in
          prev.transmission.overrideAttrs (o: {
            # sed command taken from original install.sh script
            postInstall = ''
              ${o.postInstall}
              cp -RT ${themeSrc}/web/ $out/share/transmission/web/
              sed -i '21i\\t\t<link href="./style/transmission/soft-theme.min.css" type="text/css" rel="stylesheet" />\n\t\t<link href="style/transmission/soft-dark-theme.min.css" type="text/css" rel="stylesheet" />\n' $out/share/transmission/web/index.html;
            '';
          });

        # use latest commmit from git
        # waybar = super.waybar.overrideAttrs (o:
        #   sources.waybar
        #   // {
        #     version = "${o.version}-${sources.waybar.version}";
        #   });
      }
    )
  ];
}
