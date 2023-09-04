{pkgs, ...}: let
  # include generated sources from nvfetcher
  sources = import ../_sources/generated.nix {inherit (pkgs) fetchFromGitHub fetchurl fetchgit dockerTools;};
in {
  nixpkgs.overlays = [
    (
      self: super: {
        # include custom packages
        iynaix = (super.iynaix or {}) // (import ../packages {inherit (super) pkgs;});

        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = super.imv.overrideAttrs (o: {
          patches = (o.patches or []) ++ [./imv-disable-key-repeat-timer.patch];
        });

        # add default font to silence null font errors
        lsix = super.lsix.overrideAttrs (o: {
          postFixup = ''
            substituteInPlace $out/bin/lsix \
              --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${o.postFixup}
          '';
        });

        # see below url for the latest specified version
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/path-of-building/default.nix
        path-of-building = super.path-of-building.overrideAttrs (o: {
          # passthru =
          #   o.passthru
          #   // oldAttrs.passthru.data.overrideAttrs (oldDataAttrs: {
          #     src = super.fetchFromGitHub {
          #       owner = "PathOfBuildingCommunity";
          #       repo = "PathOfBuilding";
          #       rev = "v2.33.0";
          #       hash = "sha256-8w8pbiAP0zv1O7I6WfuPmQhEnBnySqSkIZoDH5hOOyw=";
          #     };
          #   });

          # add .desktop file with icon
          desktopItem = super.makeDesktopItem {
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
        swww = super.swww.overrideAttrs (o:
          sources.swww
          // {
            version = "${o.version}-${sources.swww.version}";

            # creating an overlay for buildRustPackage overlay
            # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
            cargoDeps = super.rustPlatform.importCargoLock {
              lockFile = sources.swww.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          });

        # transmission dark mode, the default theme is hideous
        transmission = let
          themeSrc =
            super.fetchzip
            {
              url = "https://git.eigenlab.org/sbiego/transmission-web-soft-theme/-/archive/master/transmission-web-soft-theme-master.tar.gz";
              sha256 = "sha256-TAelzMJ8iFUhql2CX8lhysXKvYtH+cL6BCyMcpMaS9Q=";
            };
        in
          super.transmission.overrideAttrs (o: {
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
