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
        path-of-building = super.path-of-building.overrideAttrs (oldAttrs: rec {
          # dataVersion = "2.30.1";
          # data = runCommand "path-of-building-data" {
          #   src = fetchFromGitHub {
          #     owner = "PathOfBuildingCommunity";
          #     repo = "PathOfBuilding";
          #     rev = "v${dataVersion}";
          #     hash = "sha256-2itcALgl8eDkZylb/hmePDMILM4RxW2u5LYLbg+NNJ4=";
          #   };

          #   nativeBuildInputs = [ unzip ];
          # }

          installPhase =
            oldAttrs.installPhase
            + ''
              mkdir -p $out/share/pixmaps
              cp ${./PathOfBuilding-logo.png} $out/share/pixmaps/PathOfBuilding.png
              cp ${./PathOfBuilding-logo.svg} $out/share/pixmaps/PathOfBuilding.svg
              ln -sv "${desktopItem}/share/applications" $out/share
            '';

          desktopItem = super.makeDesktopItem {
            name = "Path of Building";
            desktopName = "Path of Building";
            comment = "Offline build planner for Path of Exile";
            exec = "pobfrontend %U";
            terminal = false;
            type = "Application";
            icon = "PathOfBuilding";
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
        transmission = super.transmission.overrideAttrs (oldAttrs: rec {
          themeSrc =
            super.fetchzip
            {
              url = "https://git.eigenlab.org/sbiego/transmission-web-soft-theme/-/archive/master/transmission-web-soft-theme-master.tar.gz";
              sha256 = "sha256-TAelzMJ8iFUhql2CX8lhysXKvYtH+cL6BCyMcpMaS9Q=";
            };
          # sed command taken from original install.sh script
          postInstall = ''
            ${oldAttrs.postInstall}
            cp -RT ${themeSrc}/web/ $out/share/transmission/web/
            sed -i '21i\\t\t<link href="./style/transmission/soft-theme.min.css" type="text/css" rel="stylesheet" />\n\t\t<link href="style/transmission/soft-dark-theme.min.css" type="text/css" rel="stylesheet" />\n' $out/share/transmission/web/index.html;
          '';
        });

        # creating an overlay for buildRustPackage overlay
        # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
        #   wallust = super.wallust.overrideAttrs (oldAttrs: rec {
        #     src = pkgs.fetchgit {
        #       url = "https://codeberg.org/explosion-mental/wallust.git";
        #       rev = "2.5.1";
        #       sha256 = "sha256-v72ddWKK2TMHKeBihYjMoJvKXiPe/yqJtdh8VQzjmVU=";
        #     };

        #     cargoDeps = pkgs.rustPlatform.importCargoLock {
        #       lockFile = src + "/Cargo.lock";
        #       allowBuiltinFetchGit = true;
        #     };
        #   });
      }
    )
  ];
}
