{...}: {
  nixpkgs.overlays = [
    (
      self: super: {
        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = super.imv.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [./imv-disable-key-repeat-timer.patch];
        });

        # add default font to silence null font errors
        lsix = super.lsix.overrideAttrs (oldAttrs: {
          postFixup = ''
            substituteInPlace $out/bin/lsix \
              --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
            ${oldAttrs.postFixup}
          '';
        });

        # add icon and .desktop file
        path-of-building = super.path-of-building.overrideAttrs (oldAttrs: {
          passthru =
            oldAttrs.passthru
            // oldAttrs.passthru.data.overrideAttrs (oldDataAttrs: {
              src = super.fetchFromGitHub {
                owner = "PathOfBuildingCommunity";
                repo = "PathOfBuilding";
                rev = "v2.32.1";
                hash = "sha256-+60n7qG4/iORNcaCvU3+N5SUtvWkG9mV7lI0KkTaNyU=";
              };
            });

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

        # creating an overlay for buildRustPackage overlay
        # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
        swww = super.swww.overrideAttrs (oldAttrs: rec {
          src = super.fetchgit {
            url = "https://github.com/Horus645/swww";
            rev = "517fbeb0f831d43d6c88dac22380536b00e7d9f1";
            sha256 = "sha256-Fx2e+UqBURY6Vxi6cePc0lK5gIEcWobMGfEx03ZOvAY=";
          };

          cargoDeps = super.rustPlatform.importCargoLock {
            lockFile = src + "/Cargo.lock";
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
          super.transmission.overrideAttrs (oldAttrs: {
            # sed command taken from original install.sh script
            postInstall = ''
              ${oldAttrs.postInstall}
              cp -RT ${themeSrc}/web/ $out/share/transmission/web/
              sed -i '21i\\t\t<link href="./style/transmission/soft-theme.min.css" type="text/css" rel="stylesheet" />\n\t\t<link href="style/transmission/soft-dark-theme.min.css" type="text/css" rel="stylesheet" />\n' $out/share/transmission/web/index.html;
            '';
          });

        waybar = let
          rev = "b7a527b122831235fb36f661d415f5f3ed378d92";
        in
          super.waybar.overrideAttrs (oldAttrs: {
            version = "${oldAttrs.version}-${rev}";

            # use latest waybar from git
            src = super.fetchgit {
              url = "https://github.com/Alexays/Waybar";
              rev = rev;
              sha256 = "sha256-IAHM93wjkBLhzEFlr8tMO36DNyOy+idwKgnUBw9EkwM=";
            };
          });
      }
    )
  ];
}
