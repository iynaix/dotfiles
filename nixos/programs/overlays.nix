{pkgs, ...}: {
  nixpkgs.overlays = [
    (self: super: {
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
    })
  ];
}
