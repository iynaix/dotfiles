{
  stdenv,
  lib,
  fetchFromGitHub,
  unzip,
  meson,
  ninja,
  pkg-config,
  qtbase,
  qttools,
  wrapQtAppsHook,
  luajit,
  source,
  makeDesktopItem,
}: let
  data = stdenv.mkDerivation (finalAttrs: (source
    // {
      pname = "path-of-building-data";
      version = "2.35.3";

      src = fetchFromGitHub {
        owner = "PathOfBuildingCommunity";
        repo = "PathOfBuilding";
        rev = "v${finalAttrs.version}";
        hash = "sha256-Vj7AYz3kD9XaZ/KNv8I4dHmVNzf3iKZm6b0g7SeL5ZY=";
      };

      nativeBuildInputs = [unzip];

      buildCommand = ''
        # I have absolutely no idea how this file is generated
        # and I don't think I want to know. The Flatpak also does this.
        unzip -j -d $out $src/runtime-win32.zip lua/sha1.lua

        # Install the actual data
        cp -r $src/src $src/runtime/lua/*.lua $src/manifest.xml $out

        # Pretend this is an official build so we don't get the ugly "dev mode" warning
        substituteInPlace $out/manifest.xml --replace '<Version' '<Version platform="nixos"'
        touch $out/installed.cfg

        # Completely stub out the update check
        chmod +w $out/src/UpdateCheck.lua
        echo 'return "none"' > $out/src/UpdateCheck.lua
      '';
    }));
  desktopItem = makeDesktopItem {
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
in
  stdenv.mkDerivation {
    pname = "path-of-building";
    version = "${data.version}";

    src = fetchFromGitHub {
      owner = "ernstp";
      repo = "pobfrontend";
      rev = "9faa19aa362f975737169824c1578d5011487c18";
      hash = "sha256-zhw2PZ6ZNMgZ2hG+a6AcYBkeg7kbBHNc2eSt4if17Wk=";
    };

    nativeBuildInputs = [meson ninja pkg-config qttools wrapQtAppsHook];
    buildInputs = [qtbase luajit luajit.pkgs.lua-curl];

    installPhase = ''
      runHook preInstall
      install -Dm555 pobfrontend $out/bin/pobfrontend
      runHook postInstall
    '';

    postInstall = ''
      mkdir -p $out/share/applications
      cp ${desktopItem}/share/applications/* $out/share/applications
    '';

    preFixup = ''
      qtWrapperArgs+=(
        --set LUA_PATH "$LUA_PATH"
        --set LUA_CPATH "$LUA_CPATH"
        --chdir "${data}"
      )
    '';

    passthru.data = data;

    meta = {
      description = "Offline build planner for Path of Exile";
      homepage = "https://pathofbuilding.community/";
      license = lib.licenses.mit;
      maintainers = [lib.maintainers.k900];
      mainProgram = "pobfrontend";
      broken = stdenv.isDarwin; # doesn't find uic6 for some reason
    };
  }
