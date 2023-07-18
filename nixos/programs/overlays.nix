{
  pkgs,
  config,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    (self: super:
      {
        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = super.imv.overrideAttrs (oldAttrs: {
          patches = [./imv-disable-key-repeat-timer.patch];
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
        wallust = super.wallust.overrideAttrs (oldAttrs: rec {
          src = pkgs.fetchgit {
            url = "https://codeberg.org/explosion-mental/wallust.git";
            rev = "c085b41968c7ea7c08f0382080340c6e1356e5fa";
            sha256 = "sha256-np03F4XxGFjWfxCKUUIm7Xlp1y9yjzkeb7F2I7dYttA=";
          };

          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = src + "/Cargo.lock";
            allowBuiltinFetchGit = true;
          };
        });
      }
      // (lib.optionalAttrs config.iynaix.smplayer.enable {
        # patch smplayer to not open an extra window under wayland
        # https://github.com/smplayer-dev/smplayer/issues/369#issuecomment-1519941318
        smplayer = super.smplayer.overrideAttrs (oldAttrs: {
          patches = [
            ./smplayer-shared-memory.patch
          ];
        });

        mpv = super.mpv-unwrapped.overrideAttrs (oldAttrs: {
          patches = [
            ./mpv-meson.patch
            ./mpv-mod.patch
          ];
        });
      }))
  ];
}
